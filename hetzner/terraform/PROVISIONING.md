# Kubernetes Cluster Provisioning on Hetzner Cloud

This directory contains Terraform configuration and provisioning scripts for deploying a production-ready Kubernetes cluster on Hetzner Cloud with MetalLB load balancer.

## Architecture

- **Master Node**: 1x control plane node (`server1`)
- **Worker Nodes**: 3x worker nodes (`agent1`, `agent2`, `agent3`)
- **Networks**:
  - Cluster Network: `10.200.40.0/24` (internal node communication)
  - Ingress Network: `10.100.40.0/24` (MetalLB LoadBalancer services)
  - Pod Network: `10.244.0.0/16` (Flannel CNI)
- **Load Balancer**: MetalLB (Layer 2 mode)
- **CNI**: Flannel
- **Cloud Integration**: Hetzner Cloud Controller Manager + CSI Driver
- **Kubernetes Version**: v1.31

## Prerequisites

1. **Terraform** installed (or OpenTofu)
2. **Bitwarden Secrets** CLI (`bws`) configured with access token
3. **SSH Key** configured in Bitwarden Secrets
4. **Hetzner Cloud API Token** stored in Bitwarden

## Deployment Steps

### 1. Deploy Infrastructure with Terraform

```bash
cd terraform/

# Set Bitwarden access token
export BWS_ACCESS_TOKEN="your-bws-token"

# Initialize Terraform
bws run --project-id YOUR_PROJECT_ID tofu init

# Plan deployment
bws run --project-id YOUR_PROJECT_ID tofu plan

# Apply infrastructure
bws run --project-id YOUR_PROJECT_ID tofu apply
```

This creates:
- 4 Hetzner Cloud servers
- Private networks (cluster + ingress)
- Firewalls
- SSH key configuration

### 2. Provision Kubernetes Cluster

#### Option A: Automated Full Deployment

```bash
cd scripts/

# Make scripts executable
chmod +x *.sh

# Set your SSH key path and Hetzner API token
export HETZNER_API_TOKEN="your-token"
export BWS_ACCESS_TOKEN="your-bws-token"  # or use bws

# Run full deployment
./deploy-cluster.sh
```

This script will:
1. Retrieve node IPs from Terraform
2. Wait for SSH availability
3. Provision the master node
4. Retrieve join command
5. Provision all worker nodes
6. Deploy MetalLB
7. Copy kubeconfig locally

#### Option B: Manual Step-by-Step Deployment

**Step 1: Provision Master Node**
```bash
# SSH to master
ssh root@<master-ip>

# Set environment variables
export HETZNER_API_TOKEN="your-token"
export HETZNER_NETWORK_ID="<from-terraform-output>"
export MASTER_PRIVATE_IP="10.200.40.11"
export MASTER_INGRESS_IP="10.100.40.11"

# Run provisioning script
bash /path/to/provision-master.sh

# Save the join command
cat /root/kubeadm-join-command.sh
```

**Step 2: Provision Worker Nodes**
```bash
# SSH to each worker
ssh root@<worker-ip>

# Set the join command from master
export JOIN_COMMAND="kubeadm join ..."

# Run provisioning script
bash /path/to/provision-worker.sh
```

**Step 3: Deploy MetalLB**
```bash
# From master or locally with kubeconfig
export KUBECONFIG=/etc/kubernetes/admin.conf  # or local path

bash /path/to/deploy-metallb.sh
```

### 3. Access the Cluster

```bash
# Copy kubeconfig from master
scp root@<master-ip>:/etc/kubernetes/admin.conf ~/.kube/config-hetzner

# Update server address to use public IP
sed -i "s|server: https://.*:6443|server: https://<master-public-ip>:6443|" ~/.kube/config-hetzner

# Use the cluster
export KUBECONFIG=~/.kube/config-hetzner
kubectl get nodes
kubectl get pods -A
```

## MetalLB Configuration

MetalLB is configured to use the **cluster-ingress-network** (`10.100.40.0/24`) for LoadBalancer services.

- **IP Pool**: `10.100.40.100` - `10.100.40.200`
- **Mode**: Layer 2 (L2Advertisement)

### Testing MetalLB

```bash
# Create a test deployment
kubectl create deployment nginx --image=nginx

# Expose as LoadBalancer
kubectl expose deployment nginx --type=LoadBalancer --port=80

# Check the assigned IP (should be from 10.100.40.100-200)
kubectl get svc nginx
```

The service will be accessible on its assigned IP within the ingress network.

## Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                             │
└────────────────────────┬────────────────────────────────┘
                         │
                ┌────────┴────────┐
                │  Hetzner Cloud  │
                │   Public IPs    │
                └────────┬────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼────┐      ┌────▼────┐     ┌────▼────┐
   │ server1 │      │ agent1  │     │ agent2  │
   │ Master  │      │ Worker  │     │ Worker  │
   └────┬────┘      └────┬────┘     └────┬────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
   ┌────▼─────────────┐      ┌──────────▼─────────────┐
   │ Cluster Network  │      │  Ingress Network       │
   │ 10.200.40.0/24   │      │  10.100.40.0/24        │
   │ (Node Comms)     │      │  (MetalLB Services)    │
   └──────────────────┘      └────────────────────────┘
            │
   ┌────────▼─────────┐
   │  Pod Network     │
   │  10.244.0.0/16   │
   │  (Flannel CNI)   │
   └──────────────────┘
```

## Firewall Rules

- **Master (server1)**: 
  - Port 80, 443 (HTTP/HTTPS) - ingress traffic
  - ICMP allowed
  
- **Workers (agent1-3)**:
  - All inbound blocked (except from cluster network)
  - Access via cluster network only

## Troubleshooting

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

### Check MetalLB
```bash
kubectl get pods -n metallb-system
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

### Check Hetzner Cloud Controller
```bash
kubectl get pods -n kube-system | grep hcloud
kubectl logs -n kube-system <hcloud-pod>
```

### Node Not Ready
```bash
# Check kubelet status
systemctl status kubelet

# Check logs
journalctl -u kubelet -f

# Check cloud controller
kubectl describe node <node-name>
```

### MetalLB Not Assigning IPs
```bash
# Check speaker logs
kubectl logs -n metallb-system -l component=speaker

# Check controller logs
kubectl logs -n metallb-system -l component=controller
```

## Cleanup

```bash
# Delete cluster (Terraform)
cd terraform/
bws run --project-id YOUR_PROJECT_ID tofu destroy

# Or manually
kubectl delete all --all -A  # Warning: deletes everything
```

## Components Versions

- Kubernetes: v1.31.0
- Containerd: 1.7.22
- Runc: 1.2.1
- CNI Plugins: 1.5.1
- MetalLB: v0.14.8
- Flannel: Latest
- Hetzner CCM: Latest
- Hetzner CSI: v2.6.0

## Security Considerations

1. Update firewall rules for production
2. Enable RBAC properly
3. Use network policies
4. Rotate tokens regularly
5. Use private registry for images
6. Enable audit logging
7. Consider using WireGuard for additional encryption

## Next Steps

1. **Install Ingress Controller** (nginx, traefik, etc.)
2. **Configure DNS** for services
3. **Set up monitoring** (Prometheus, Grafana)
4. **Configure backups** (Velero)
5. **Deploy applications**

## References

- [Hetzner Cloud Controller Manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
- [Hetzner CSI Driver](https://github.com/hetznercloud/csi-driver)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
