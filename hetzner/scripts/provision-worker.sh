#!/usr/bin/env bash
set -euo pipefail

# K8s Worker Node Provisioning Script for Hetzner Cloud
# This script provisions a Kubernetes worker node with:
# - Containerd runtime
# - Kubernetes v1.31
# - Required configurations for Hetzner Cloud

# --- Configuration ---
KUBE_VERSION="v1.31.0"
CONTAINERD_VERSION="1.7.22"
RUNC_VERSION="1.2.1"
CNI_PLUGINS_VERSION="1.5.1"

# Join command (must be provided)
JOIN_COMMAND="${JOIN_COMMAND:-}"

# --- Helpers ---
ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root. Use sudo." >&2
    exit 2
  fi
}

inform() { 
  echo "✓ [worker] $*" 
}

error() {
  echo "❌ [worker] ERROR: $*" >&2
  exit 1
}

# --- Begin ---
ensure_root
inform "Starting worker node provisioning for Kubernetes ${KUBE_VERSION}"

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

# --- Join the Cluster ---
if [ -z "${JOIN_COMMAND}" ]; then
  error "JOIN_COMMAND not provided. Please set it before running this script."
  echo ""
  echo "To get the join command, run on the master node:"
  echo "  kubeadm token create --print-join-command"
  echo ""
  echo "Then run this script with:"
  echo "  sudo JOIN_COMMAND='<join command>' ./provision-worker.sh"
  echo ""
  exit 1
fi

inform "Joining the cluster..."
eval "${JOIN_COMMAND}"

# --- Print Status ---
inform "Worker node provisioning complete!"
echo ""
echo "================================================"
echo "Kubernetes Worker Node Setup Complete"
echo "================================================"
echo ""
echo "This node has been joined to the cluster."
echo ""
echo "To verify from the master node:"
echo "  kubectl get nodes"
echo ""
echo "To check pod status:"
echo "  kubectl get pods -A"
echo "================================================"
