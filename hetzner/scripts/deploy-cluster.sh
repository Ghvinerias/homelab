#!/usr/bin/env bash
set -euo pipefail

# Complete K8s Cluster Deployment Script for Hetzner Cloud
# This script orchestrates the full deployment process

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_NODE="server1"
WORKER_NODES=("agent1" "agent2" "agent3")
SSH_USER="root"
SSH_KEY="${HOME}/.ssh/id_ed25519"  # Adjust to your SSH key

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Helpers ---
inform() { 
  echo -e "${GREEN}✓${NC} $*" 
}

warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

error() {
  echo -e "${RED}❌ ERROR:${NC} $*" >&2
  exit 1
}

check_ssh_key() {
  if [ ! -f "${SSH_KEY}" ]; then
    error "SSH key not found at ${SSH_KEY}. Please update SSH_KEY variable."
  fi
}

get_node_ip() {
  local node_name=$1
  cd "${SCRIPT_DIR}/../terraform"
  terraform output -json | jq -r ".hetzner_servers.value[\"${node_name}\"].ipv4_address" 2>/dev/null || echo ""
}

wait_for_ssh() {
  local host=$1
  local max_attempts=30
  local attempt=1
  
  inform "Waiting for SSH to be available on ${host}..."
  while [ $attempt -le $max_attempts ]; do
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${host}" "echo 'SSH Ready'" &>/dev/null; then
      return 0
    fi
    echo -n "."
    sleep 10
    ((attempt++))
  done
  
  error "SSH not available on ${host} after ${max_attempts} attempts"
}

# --- Begin ---
echo ""
echo "================================================"
echo "Kubernetes Cluster Deployment"
echo "================================================"
echo ""

check_ssh_key

# --- Step 1: Get Node IPs ---
inform "Retrieving node IPs from Terraform..."
MASTER_IP=$(get_node_ip "${MASTER_NODE}")
if [ -z "${MASTER_IP}" ]; then
  error "Could not retrieve IP for master node ${MASTER_NODE}. Is Terraform deployed?"
fi
inform "Master node (${MASTER_NODE}): ${MASTER_IP}"

declare -A WORKER_IPS
for worker in "${WORKER_NODES[@]}"; do
  ip=$(get_node_ip "${worker}")
  if [ -z "${ip}" ]; then
    error "Could not retrieve IP for worker node ${worker}"
  fi
  WORKER_IPS["${worker}"]="${ip}"
  inform "Worker node (${worker}): ${ip}"
done

# --- Step 2: Wait for SSH ---
inform "Waiting for all nodes to be SSH accessible..."
wait_for_ssh "${MASTER_IP}"
for worker in "${WORKER_NODES[@]}"; do
  wait_for_ssh "${WORKER_IPS[${worker}]}"
done

# --- Step 3: Get Hetzner Network ID ---
inform "Retrieving Hetzner network ID from Terraform..."
cd "${SCRIPT_DIR}/../terraform"
HETZNER_NETWORK_ID=$(terraform output -raw hetzner_cluster_network_id 2>/dev/null) || error "Could not get network ID"
inform "Hetzner network ID: ${HETZNER_NETWORK_ID}"

# Get Hetzner API token from environment or Bitwarden
HETZNER_API_TOKEN="${HETZNER_API_TOKEN:-}"
if [ -z "${HETZNER_API_TOKEN}" ]; then
  warning "HETZNER_API_TOKEN not set. Attempting to retrieve from Bitwarden..."
  if command -v bws &> /dev/null && [ -n "${BWS_ACCESS_TOKEN:-}" ]; then
    HETZNER_API_TOKEN=$(bws secret get 5cc33b68-00c5-41c1-9249-b36b00b04efd --output json | jq -r '.value' 2>/dev/null) || true
  fi
  
  if [ -z "${HETZNER_API_TOKEN}" ]; then
    error "HETZNER_API_TOKEN not available. Please export it or ensure Bitwarden access."
  fi
fi

# --- Step 4: Provision Master Node ---
inform "Provisioning master node..."
ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${MASTER_IP}" "bash -s" <<EOF_MASTER
export HETZNER_API_TOKEN="${HETZNER_API_TOKEN}"
export HETZNER_NETWORK_ID="${HETZNER_NETWORK_ID}"
export MASTER_PRIVATE_IP="10.200.40.11"
export MASTER_INGRESS_IP="10.100.40.11"

$(cat "${SCRIPT_DIR}/provision-master.sh")
EOF_MASTER

if [ $? -ne 0 ]; then
  error "Master node provisioning failed"
fi

# --- Step 5: Get Join Command ---
inform "Retrieving join command from master..."
sleep 10  # Give master a moment to finalize
JOIN_COMMAND=$(ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${MASTER_IP}" "cat /root/kubeadm-join-command.sh")

if [ -z "${JOIN_COMMAND}" ]; then
  error "Could not retrieve join command from master"
fi

# --- Step 6: Provision Worker Nodes ---
for worker in "${WORKER_NODES[@]}"; do
  worker_ip="${WORKER_IPS[${worker}]}"
  inform "Provisioning worker node ${worker} (${worker_ip})..."
  
  ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${worker_ip}" "bash -s" <<EOF_WORKER
export JOIN_COMMAND="${JOIN_COMMAND}"

$(cat "${SCRIPT_DIR}/provision-worker.sh")
EOF_WORKER

  if [ $? -ne 0 ]; then
    error "Worker node ${worker} provisioning failed"
  fi
done

# --- Step 7: Verify Cluster ---
inform "Waiting for all nodes to join the cluster..."
sleep 20

inform "Retrieving cluster status..."
ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${MASTER_IP}" "kubectl get nodes"

# --- Step 8: Copy kubeconfig ---
inform "Copying kubeconfig locally..."
mkdir -p "${HOME}/.kube"
scp -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${MASTER_IP}:/etc/kubernetes/admin.conf" "${HOME}/.kube/config-hetzner"

# Update server address to use public IP
sed -i.bak "s|server: https://.*:6443|server: https://${MASTER_IP}:6443|" "${HOME}/.kube/config-hetzner"

inform "Kubeconfig saved to ${HOME}/.kube/config-hetzner"
echo ""
echo "To use this cluster, run:"
echo "  export KUBECONFIG=${HOME}/.kube/config-hetzner"
echo ""

# --- Step 9: Deploy MetalLB ---
inform "Deploying MetalLB..."
export KUBECONFIG="${HOME}/.kube/config-hetzner"

ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${MASTER_IP}" "bash -s" <<'EOF_METALLB'
$(cat "${SCRIPT_DIR}/deploy-metallb.sh")
EOF_METALLB

if [ $? -ne 0 ]; then
  warning "MetalLB deployment encountered issues. You may need to deploy it manually."
fi

# --- Final Status ---
echo ""
echo "================================================"
echo "Cluster Deployment Complete!"
echo "================================================"
echo ""
inform "Cluster nodes:"
kubectl --kubeconfig="${HOME}/.kube/config-hetzner" get nodes
echo ""
inform "All pods:"
kubectl --kubeconfig="${HOME}/.kube/config-hetzner" get pods -A
echo ""
echo "Next steps:"
echo "  1. Export kubeconfig: export KUBECONFIG=${HOME}/.kube/config-hetzner"
echo "  2. Test MetalLB with a sample LoadBalancer service"
echo "  3. Deploy your applications"
echo ""
echo "To test MetalLB:"
echo "  kubectl create deployment nginx --image=nginx"
echo "  kubectl expose deployment nginx --type=LoadBalancer --port=80"
echo "  kubectl get svc nginx  # Check for EXTERNAL-IP"
echo ""
echo "================================================"
