#!/usr/bin/env bash
set -euo pipefail

# K8s Master Node Provisioning Script for Hetzner Cloud
# This script provisions a Kubernetes master node with:
# - Containerd runtime
# - Kubernetes v1.31
# - Hetzner Cloud Controller Manager
# - Flannel CNI
# - Hetzner CSI Driver

# --- Configuration ---
KUBE_VERSION="v1.31.0"
CONTAINERD_VERSION="1.7.22"
RUNC_VERSION="1.2.1"
CNI_PLUGINS_VERSION="1.5.1"

# Network configuration
POD_NETWORK_CIDR="10.244.0.0/16"
CLUSTER_NETWORK_CIDR="10.200.40.0/24"
INGRESS_NETWORK_CIDR="10.100.40.0/24"

# Hetzner specific (these will be passed from Terraform via cloud-init)
HETZNER_API_TOKEN="${HETZNER_API_TOKEN:-}"
HETZNER_NETWORK_ID="${HETZNER_NETWORK_ID:-}"
MASTER_PRIVATE_IP="${MASTER_PRIVATE_IP:-10.200.40.11}"
MASTER_INGRESS_IP="${MASTER_INGRESS_IP:-10.100.40.11}"

# --- Helpers ---
ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root. Use sudo." >&2
    exit 2
  fi
}

inform() { 
  echo "✓ [master] $*" 
}

error() {
  echo "❌ [master] ERROR: $*" >&2
  exit 1
}

# --- Begin ---
ensure_root
inform "Starting master node provisioning for Kubernetes ${KUBE_VERSION}"

# --- System Preparation ---
inform "Disabling swap (required for K8s)..."
swapoff -a
sed -i '/\sswap\s/s/^/#/' /etc/fstab

# --- Load Kernel Modules ---
inform "Loading required kernel modules..."
cat > /etc/modules-load.d/k8s.conf <<'EOF'
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# --- Configure Sysctl ---
inform "Configuring sysctl settings for Kubernetes..."
cat > /etc/sysctl.d/k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv6.conf.default.forwarding    = 1
EOF

sysctl --system

# --- Install Containerd ---
inform "Installing containerd ${CONTAINERD_VERSION}..."
cd /tmp
wget -q "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"
tar Czxvf /usr/local "containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"

# Install containerd systemd service
wget -q https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /usr/lib/systemd/system/containerd.service

# --- Install runc ---
inform "Installing runc ${RUNC_VERSION}..."
wget -q "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
install -m 755 runc.amd64 /usr/local/sbin/runc

# --- Install CNI Plugins ---
inform "Installing CNI plugins ${CNI_PLUGINS_VERSION}..."
mkdir -p /opt/cni/bin
wget -q "https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz"
tar Czxvf /opt/cni/bin "cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz"

# --- Configure Containerd ---
inform "Configuring containerd with systemd cgroup driver..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null

# Enable systemd cgroup driver
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Start containerd
systemctl daemon-reload
systemctl enable --now containerd
systemctl status containerd --no-pager

# --- Configure Kubelet for External Cloud Provider ---
inform "Configuring kubelet for Hetzner Cloud external provider..."
mkdir -p /etc/systemd/system/kubelet.service.d
cat > /etc/systemd/system/kubelet.service.d/20-hetzner-cloud.conf <<'EOF'
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF

# --- Install Kubernetes Components ---
inform "Installing Kubernetes components (kubeadm, kubelet, kubectl)..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# --- Initialize Kubernetes Control Plane ---
inform "Pulling kubeadm images..."
kubeadm config images pull

inform "Initializing Kubernetes control plane..."
kubeadm init \
  --pod-network-cidr="${POD_NETWORK_CIDR}" \
  --kubernetes-version="${KUBE_VERSION}" \
  --apiserver-advertise-address="${MASTER_PRIVATE_IP}" \
  --apiserver-cert-extra-sans="${MASTER_PRIVATE_IP},${MASTER_INGRESS_IP}" \
  --ignore-preflight-errors=NumCPU \
  --upload-certs

# --- Configure kubectl for root ---
inform "Configuring kubectl for root user..."
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# --- Create Hetzner Secrets ---
if [ -n "${HETZNER_API_TOKEN}" ] && [ -n "${HETZNER_NETWORK_ID}" ]; then
  inform "Creating Hetzner Cloud secrets..."
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: hcloud
  namespace: kube-system
stringData:
  token: "${HETZNER_API_TOKEN}"
  network: "${HETZNER_NETWORK_ID}"
---
apiVersion: v1
kind: Secret
metadata:
  name: hcloud-csi
  namespace: kube-system
stringData:
  token: "${HETZNER_API_TOKEN}"
EOF
else
  error "HETZNER_API_TOKEN or HETZNER_NETWORK_ID not set. Cannot create secrets."
fi

# --- Deploy Hetzner Cloud Controller Manager ---
inform "Deploying Hetzner Cloud Controller Manager..."
kubectl apply -f https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml

# --- Deploy Flannel CNI ---
inform "Deploying Flannel CNI..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Wait for Flannel to be deployed
sleep 10

# --- Patch Tolerations ---
inform "Patching tolerations for Flannel and CoreDNS..."
kubectl -n kube-flannel patch ds kube-flannel-ds --type json \
  -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]' || true

kubectl -n kube-system patch deployment coredns --type json \
  -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]' || true

# --- Deploy Hetzner CSI Driver ---
inform "Deploying Hetzner CSI Driver..."
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v2.6.0/deploy/kubernetes/hcloud-csi.yml

# --- Save Join Command ---
inform "Generating worker join command..."
JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo "${JOIN_COMMAND}" > /root/kubeadm-join-command.sh
chmod +x /root/kubeadm-join-command.sh

# --- Print Status ---
inform "Master node provisioning complete!"
echo ""
echo "================================================"
echo "Kubernetes Master Node Setup Complete"
echo "================================================"
echo ""
echo "To join worker nodes to this cluster, run the following command on each worker:"
echo ""
cat /root/kubeadm-join-command.sh
echo ""
echo "Or retrieve it later with: cat /root/kubeadm-join-command.sh"
echo ""
echo "To use kubectl:"
echo "  export KUBECONFIG=/etc/kubernetes/admin.conf"
echo ""
echo "To check cluster status:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo ""
echo "Next steps:"
echo "  1. Join worker nodes using the command above"
echo "  2. Deploy MetalLB using deploy-metallb.sh"
echo "================================================"
