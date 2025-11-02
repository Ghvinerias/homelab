# Hetzner Cloud Kubernetes Cluster

Complete Terraform + provisioning scripts for deploying a production-ready Kubernetes cluster on Hetzner Cloud with MetalLB load balancer.

## 📁 Project Structure

```
hetzner/
├── terraform/
│   ├── main.tf                      # Terraform configuration
│   ├── cloud-init-master.yml        # Cloud-init for master node
│   ├── cloud-init-worker.yml        # Cloud-init for worker nodes
│   └── PROVISIONING.md              # Detailed provisioning docs
│
├── scripts/
│   ├── provision-master.sh          # Master node setup (K8s v1.31)
│   ├── provision-worker.sh          # Worker node setup
│   ├── deploy-metallb.sh            # MetalLB installation
│   ├── deploy-cluster.sh            # Automated full deployment
│   └── cluster-helper.sh            # Management utilities
│
├── Makefile                         # Convenient make targets
├── QUICKSTART.md                    # Quick reference guide
└── README.md                        # This file
```

## 🚀 Quick Start

### Prerequisites

- Terraform/OpenTofu installed
- Bitwarden Secrets CLI (`bws`)
- SSH key configured
- Hetzner Cloud account with API token

### Deploy Everything (5 minutes)

```bash
# 1. Set environment
export BWS_ACCESS_TOKEN="your-token"

# 2. Deploy infrastructure
make apply

# 3. Deploy K8s cluster + MetalLB
make deploy

# 4. Get kubeconfig
make kubeconfig
export KUBECONFIG=~/.kube/config-hetzner

# 5. Check status
make status
```

Or use one command:
```bash
make quick-deploy
```

## 🏗️ Architecture

### Infrastructure
- **1 Master Node** (`server1`) - Control plane
- **3 Worker Nodes** (`agent1-3`) - Workload nodes
- **Server Type**: `cx23` (2 vCPU, 4GB RAM)
- **Location**: Nuremberg (`nbg1`)

### Networking
```
┌─────────────────────────────────────────┐
│ Cluster Network: 10.200.40.0/24        │
│ - Node-to-node communication           │
│ - Private IPs: .11 (master), .21-.23   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Ingress Network: 10.100.40.0/24        │
│ - MetalLB LoadBalancer IPs             │
│ - Pool: 10.100.40.100-200 (100 IPs)   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Pod Network: 10.244.0.0/16             │
│ - Flannel CNI                          │
└─────────────────────────────────────────┘
```

### Components
- **Kubernetes**: v1.31.0
- **Container Runtime**: Containerd 1.7.22
- **CNI**: Flannel (latest)
- **Load Balancer**: MetalLB v0.14.8 (Layer 2)
- **Cloud Integration**: Hetzner CCM + CSI Driver
- **Storage**: Hetzner CSI for persistent volumes

## 📖 Usage

### Using Makefile (Recommended)

```bash
# Infrastructure
make init            # Initialize Terraform
make plan            # Plan changes
make apply           # Create infrastructure

# Deployment
make deploy          # Deploy complete cluster
make deploy-metallb  # Deploy only MetalLB

# Management
make status          # Cluster status
make kubeconfig      # Get kubeconfig
make nodes           # List nodes
make pods            # List all pods
make services        # List all services

# Testing
make test-lb         # Test LoadBalancer
make endpoints       # Show LB endpoints

# Access
make ssh-master      # SSH to master
make ssh-agent1      # SSH to agent1

# Cleanup
make destroy         # Destroy everything
```

### Using Scripts Directly

```bash
cd scripts/

# Full automated deployment
./deploy-cluster.sh

# Individual components
./provision-master.sh
./provision-worker.sh
./deploy-metallb.sh

# Management
./cluster-helper.sh status
./cluster-helper.sh ssh server1
./cluster-helper.sh test-metallb
```

### Using kubectl

```bash
export KUBECONFIG=~/.kube/config-hetzner

# Check cluster
kubectl get nodes
kubectl get pods -A

# Deploy an app with LoadBalancer
kubectl create deployment web --image=nginx
kubectl expose deployment web --type=LoadBalancer --port=80

# Get the LoadBalancer IP
kubectl get svc web
# Access at http://<EXTERNAL-IP>
```

## 🔧 MetalLB Configuration

MetalLB is configured to use the **cluster-ingress-network** for LoadBalancer services:

- **Network**: `10.100.40.0/24`
- **IP Pool**: `10.100.40.100` - `10.100.40.200`
- **Mode**: Layer 2 (L2Advertisement)
- **Auto-assign**: Yes

When you create a `LoadBalancer` service, MetalLB automatically assigns an IP from this pool.

### Testing MetalLB

```bash
# Quick test
make test-lb

# Manual test
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80
kubectl get svc nginx  # Wait for EXTERNAL-IP

# Get the IP
NGINX_IP=$(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Service available at: http://${NGINX_IP}"

# Test from a node (IPs are on ingress network)
make ssh-master
curl http://${NGINX_IP}
```

## 🔍 Troubleshooting

### Cluster Issues

```bash
# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check kubelet on a node
make ssh-master
journalctl -u kubelet -f
```

### MetalLB Issues

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check speaker logs
kubectl logs -n metallb-system -l component=speaker

# Check controller logs
kubectl logs -n metallb-system -l component=controller

# Verify configuration
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

### Network Issues

```bash
# Check Hetzner CCM
kubectl get pods -n kube-system | grep hcloud
kubectl logs -n kube-system <hcloud-ccm-pod>

# Check Flannel
kubectl get pods -n kube-flannel

# Test node connectivity (from master)
make ssh-master
ping 10.200.40.21  # agent1 cluster IP
ping 10.100.40.21  # agent1 ingress IP
```

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference commands
- **[terraform/PROVISIONING.md](terraform/PROVISIONING.md)** - Detailed deployment guide
- **[Hetzner CCM](https://github.com/hetznercloud/hcloud-cloud-controller-manager)** - Cloud controller docs
- **[MetalLB](https://metallb.universe.tf/)** - Load balancer docs

## 🛠️ Customization

### Change IP Ranges

Edit `scripts/provision-master.sh`:
```bash
POD_NETWORK_CIDR="10.244.0.0/16"      # Flannel pods
CLUSTER_NETWORK_CIDR="10.200.40.0/24" # Node network
INGRESS_NETWORK_CIDR="10.100.40.0/24" # LoadBalancer network
```

Edit `scripts/deploy-metallb.sh`:
```bash
LB_IP_RANGE_START="10.100.40.100"
LB_IP_RANGE_END="10.100.40.200"
```

Edit `terraform/main.tf` for network configuration.

### Change Kubernetes Version

Edit both `provision-master.sh` and `provision-worker.sh`:
```bash
KUBE_VERSION="v1.31.0"  # Change to desired version
```

### Add More Nodes

Edit `terraform/main.tf`:
```hcl
variable "node_configs" {
  default = [
    # ... existing nodes ...
    {
      name                    = "agent4"
      cloud_init_id           = "your-bitwarden-id"
      node_internal_ip        = "10.200.40.24"
      node_cluster_ingress_ip = "10.100.40.24"
      firewall_group          = "block-all-inbound"
    },
  ]
}
```

## 🔐 Security

- ✅ Firewall rules (only ports 80/443 on master)
- ✅ SSH key authentication only
- ✅ Secrets stored in Bitwarden
- ✅ External cloud provider (Hetzner CCM)
- ✅ Private networks for internal traffic

**Production recommendations:**
1. Enable network policies
2. Configure RBAC properly
3. Use private container registry
4. Enable audit logging
5. Rotate credentials regularly
6. Add monitoring (Prometheus/Grafana)

## 🧹 Cleanup

```bash
# Destroy everything
make destroy

# Or manually
cd terraform/
tofu destroy
```

## 📊 Cost Estimate

Based on Hetzner Cloud pricing (as of 2024):
- 4x CX23 servers (~€8/month each)
- 2x Private networks (free)
- Traffic (free for first 20TB)

**Total**: ~€32/month

## 🎯 Next Steps

After deployment:

1. **Install Ingress Controller**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
   ```

2. **Install cert-manager** (for TLS)
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

3. **Setup Monitoring**
   - Prometheus + Grafana
   - Hetzner metrics via CCM

4. **Configure DNS**
   - Point your domain to LoadBalancer IPs
   - Use Cloudflare or similar

5. **Deploy Applications**
   - Use the cluster for your workloads!

## 🤝 Contributing

Found an issue or want to improve something? Feel free to:
- Open an issue
- Submit a pull request
- Share feedback

## 📝 License

MIT License - Feel free to use and modify!

## 🙏 Acknowledgments

- [Hetzner Cloud](https://www.hetzner.com/cloud) for affordable infrastructure
- [MetalLB](https://metallb.universe.tf/) for the load balancer
- [Kubernetes](https://kubernetes.io/) community

---

**Need Help?** Check the troubleshooting section or open an issue!
