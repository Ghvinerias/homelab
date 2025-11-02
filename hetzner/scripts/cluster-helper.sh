#!/usr/bin/env bash
# Quick helper commands for managing the Hetzner K8s cluster

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_PATH="${HOME}/.kube/config-hetzner"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
  cat <<EOF
Hetzner K8s Cluster Helper Script

Usage: $0 <command> [options]

Commands:
  status              Show cluster status (nodes, pods, services)
  get-kubeconfig      Copy kubeconfig from master node
  get-join-command    Retrieve the worker join command from master
  test-metallb        Deploy a test nginx service with LoadBalancer
  logs <node>         Show kubelet logs from a specific node
  ssh <node>          SSH into a node (server1, agent1, agent2, agent3)
  endpoints           Show all LoadBalancer service endpoints
  destroy             Destroy the entire cluster (Terraform)
  help                Show this help message

Environment Variables:
  SSH_KEY            Path to SSH key (default: ~/.ssh/id_ed25519)
  BWS_PROJECT_ID     Bitwarden Secrets project ID

Examples:
  $0 status
  $0 get-kubeconfig
  $0 ssh server1
  $0 test-metallb
  $0 logs agent1
  $0 endpoints

EOF
}

get_node_ip() {
  local node_name=$1
  cd "${SCRIPT_DIR}/../terraform"
  terraform output -json 2>/dev/null | jq -r ".hetzner_servers.value[\"${node_name}\"].ipv4_address" || echo ""
}

get_master_ip() {
  get_node_ip "server1"
}

cmd_status() {
  if [ ! -f "${KUBECONFIG_PATH}" ]; then
    echo -e "${RED}Kubeconfig not found at ${KUBECONFIG_PATH}${NC}"
    echo "Run: $0 get-kubeconfig"
    exit 1
  fi
  
  echo -e "${GREEN}=== Cluster Nodes ===${NC}"
  kubectl --kubeconfig="${KUBECONFIG_PATH}" get nodes -o wide
  echo ""
  
  echo -e "${GREEN}=== All Pods ===${NC}"
  kubectl --kubeconfig="${KUBECONFIG_PATH}" get pods -A
  echo ""
  
  echo -e "${GREEN}=== LoadBalancer Services ===${NC}"
  kubectl --kubeconfig="${KUBECONFIG_PATH}" get svc -A | grep LoadBalancer || echo "No LoadBalancer services found"
  echo ""
  
  echo -e "${GREEN}=== MetalLB Status ===${NC}"
  kubectl --kubeconfig="${KUBECONFIG_PATH}" get pods -n metallb-system 2>/dev/null || echo "MetalLB not deployed"
}

cmd_get_kubeconfig() {
  local master_ip
  master_ip=$(get_master_ip)
  
  if [ -z "${master_ip}" ]; then
    echo -e "${RED}Could not get master IP. Is Terraform deployed?${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Copying kubeconfig from ${master_ip}...${NC}"
  mkdir -p "${HOME}/.kube"
  scp -o StrictHostKeyChecking=no -i "${SSH_KEY:-${HOME}/.ssh/id_ed25519}" \
    "root@${master_ip}:/etc/kubernetes/admin.conf" "${KUBECONFIG_PATH}"
  
  # Update server address
  sed -i.bak "s|server: https://.*:6443|server: https://${master_ip}:6443|" "${KUBECONFIG_PATH}"
  
  echo -e "${GREEN}Kubeconfig saved to ${KUBECONFIG_PATH}${NC}"
  echo ""
  echo "To use this cluster, run:"
  echo "  export KUBECONFIG=${KUBECONFIG_PATH}"
}

cmd_get_join_command() {
  local master_ip
  master_ip=$(get_master_ip)
  
  if [ -z "${master_ip}" ]; then
    echo -e "${RED}Could not get master IP. Is Terraform deployed?${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Retrieving join command from ${master_ip}...${NC}"
  ssh -o StrictHostKeyChecking=no -i "${SSH_KEY:-${HOME}/.ssh/id_ed25519}" \
    "root@${master_ip}" "cat /root/kubeadm-join-command.sh"
}

cmd_test_metallb() {
  if [ ! -f "${KUBECONFIG_PATH}" ]; then
    echo -e "${RED}Kubeconfig not found. Run: $0 get-kubeconfig${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Deploying test nginx service...${NC}"
  kubectl --kubeconfig="${KUBECONFIG_PATH}" create deployment nginx-test --image=nginx 2>/dev/null || echo "Deployment already exists"
  kubectl --kubeconfig="${KUBECONFIG_PATH}" expose deployment nginx-test --type=LoadBalancer --port=80 --name=nginx-test 2>/dev/null || echo "Service already exists"
  
  echo ""
  echo -e "${GREEN}Waiting for LoadBalancer IP assignment...${NC}"
  sleep 5
  
  kubectl --kubeconfig="${KUBECONFIG_PATH}" get svc nginx-test
  
  echo ""
  echo "To test the service:"
  echo "  NGINX_IP=\$(kubectl --kubeconfig=${KUBECONFIG_PATH} get svc nginx-test -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  echo "  curl http://\${NGINX_IP}"
}

cmd_logs() {
  local node_name=$1
  local node_ip
  
  if [ -z "${node_name}" ]; then
    echo -e "${RED}Node name required${NC}"
    echo "Usage: $0 logs <node>"
    echo "Nodes: server1, agent1, agent2, agent3"
    exit 1
  fi
  
  node_ip=$(get_node_ip "${node_name}")
  if [ -z "${node_ip}" ]; then
    echo -e "${RED}Could not get IP for ${node_name}${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Kubelet logs from ${node_name} (${node_ip}):${NC}"
  ssh -o StrictHostKeyChecking=no -i "${SSH_KEY:-${HOME}/.ssh/id_ed25519}" \
    "root@${node_ip}" "journalctl -u kubelet -n 100 --no-pager"
}

cmd_ssh() {
  local node_name=$1
  local node_ip
  
  if [ -z "${node_name}" ]; then
    echo -e "${RED}Node name required${NC}"
    echo "Usage: $0 ssh <node>"
    echo "Nodes: server1, agent1, agent2, agent3"
    exit 1
  fi
  
  node_ip=$(get_node_ip "${node_name}")
  if [ -z "${node_ip}" ]; then
    echo -e "${RED}Could not get IP for ${node_name}${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Connecting to ${node_name} (${node_ip})...${NC}"
  ssh -o StrictHostKeyChecking=no -i "${SSH_KEY:-${HOME}/.ssh/id_ed25519}" "root@${node_ip}"
}

cmd_endpoints() {
  if [ ! -f "${KUBECONFIG_PATH}" ]; then
    echo -e "${RED}Kubeconfig not found. Run: $0 get-kubeconfig${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}=== LoadBalancer Service Endpoints ===${NC}"
  echo ""
  kubectl --kubeconfig="${KUBECONFIG_PATH}" get svc -A -o json | \
    jq -r '.items[] | select(.spec.type=="LoadBalancer") | 
    "\(.metadata.namespace)/\(.metadata.name): \(.status.loadBalancer.ingress[0].ip // "pending")"'
}

cmd_destroy() {
  echo -e "${RED}WARNING: This will destroy the entire cluster!${NC}"
  read -p "Are you sure? Type 'yes' to confirm: " confirm
  
  if [ "${confirm}" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
  
  cd "${SCRIPT_DIR}/../terraform"
  
  if [ -n "${BWS_PROJECT_ID:-}" ]; then
    bws run --project-id "${BWS_PROJECT_ID}" terraform destroy
  else
    terraform destroy
  fi
}

# Main
case "${1:-help}" in
  status)
    cmd_status
    ;;
  get-kubeconfig)
    cmd_get_kubeconfig
    ;;
  get-join-command)
    cmd_get_join_command
    ;;
  test-metallb)
    cmd_test_metallb
    ;;
  logs)
    cmd_logs "${2:-}"
    ;;
  ssh)
    cmd_ssh "${2:-}"
    ;;
  endpoints)
    cmd_endpoints
    ;;
  destroy)
    cmd_destroy
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    echo ""
    show_help
    exit 1
    ;;
esac
