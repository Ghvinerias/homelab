#!/usr/bin/env bash
set -euo pipefail

# MetalLB Deployment Script for Hetzner Cloud
# This script deploys MetalLB as a LoadBalancer for the K8s cluster
# and configures it to use the Hetzner cluster-ingress-network (10.100.40.0/24)

# --- Configuration ---
METALLB_VERSION="v0.14.8"
INGRESS_NETWORK_CIDR="10.100.40.0/24"
# IP range for LoadBalancer services (using a subset of the ingress network)
# Reserve .1-.10 for control plane, .11-.20 for nodes, .100-.200 for services
LB_IP_RANGE_START="10.100.40.100"
LB_IP_RANGE_END="10.100.40.200"

# --- Helpers ---
ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️  This script doesn't require root, but kubectl must be configured." >&2
  fi
}

inform() { 
  echo "✓ [metallb] $*" 
}

error() {
  echo "❌ [metallb] ERROR: $*" >&2
  exit 1
}

check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    error "kubectl not found. Please install kubectl and configure access to the cluster."
  fi
  
  if ! kubectl cluster-info &> /dev/null; then
    error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
  fi
}

# --- Begin ---
inform "Starting MetalLB deployment (version ${METALLB_VERSION})"

check_kubectl

# --- Deploy MetalLB ---
inform "Deploying MetalLB using official manifests..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml

inform "Waiting for MetalLB pods to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=120s || error "MetalLB pods did not become ready in time"

# Give MetalLB a moment to fully initialize
sleep 5

# --- Configure MetalLB IP Address Pool ---
inform "Creating MetalLB IP address pool for LoadBalancer services..."
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: hetzner-ingress-pool
  namespace: metallb-system
spec:
  addresses:
  - ${LB_IP_RANGE_START}-${LB_IP_RANGE_END}
  autoAssign: true
EOF

# --- Configure L2 Advertisement ---
inform "Configuring L2 advertisement for the IP pool..."
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: hetzner-ingress-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - hetzner-ingress-pool
EOF

# --- Verify Installation ---
inform "Verifying MetalLB installation..."
echo ""
echo "MetalLB Pods:"
kubectl get pods -n metallb-system
echo ""
echo "MetalLB IP Address Pools:"
kubectl get ipaddresspool -n metallb-system
echo ""
echo "MetalLB L2 Advertisements:"
kubectl get l2advertisement -n metallb-system
echo ""

# --- Print Status ---
inform "MetalLB deployment complete!"
echo ""
echo "================================================"
echo "MetalLB LoadBalancer Setup Complete"
echo "================================================"
echo ""
echo "Configuration:"
echo "  Network: ${INGRESS_NETWORK_CIDR}"
echo "  IP Range: ${LB_IP_RANGE_START} - ${LB_IP_RANGE_END}"
echo "  Mode: Layer 2 (L2Advertisement)"
echo ""
echo "To test MetalLB, create a LoadBalancer service:"
echo ""
cat <<'EXAMPLE'
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80

# Wait a moment, then check the external IP
kubectl get svc nginx

# The EXTERNAL-IP should be from the range 10.100.40.100-200
EXAMPLE
echo ""
echo "To access LoadBalancer services from outside the cluster:"
echo "  1. Ensure the Hetzner ingress network (10.100.40.0/24) is properly routed"
echo "  2. Services will be accessible on their assigned IPs within this network"
echo "  3. Consider setting up an ingress controller for HTTP/HTTPS traffic"
echo ""
echo "================================================"
