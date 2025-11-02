# Quick Start Guide - Hetzner K8s Cluster

## 🚀 Deployment (One Command)

```bash
cd hetzner/scripts
export BWS_ACCESS_TOKEN="your-token"
./deploy-cluster.sh
```

## 📋 Common Commands

### Cluster Management
```bash
# Check cluster status
./cluster-helper.sh status

# Get kubeconfig
./cluster-helper.sh get-kubeconfig
export KUBECONFIG=~/.kube/config-hetzner

# SSH to a node
./cluster-helper.sh ssh server1
./cluster-helper.sh ssh agent1

# Get join command for new workers
./cluster-helper.sh get-join-command

# View logs from a node
./cluster-helper.sh logs server1
```

### MetalLB Testing
```bash
# Test LoadBalancer
./cluster-helper.sh test-metallb

# View all LoadBalancer endpoints
./cluster-helper.sh endpoints

# Check MetalLB status
kubectl get pods -n metallb-system
kubectl get ipaddresspool -n metallb-system
```

### Manual Commands
```bash
# Create a LoadBalancer service
kubectl create deployment myapp --image=nginx
kubectl expose deployment myapp --type=LoadBalancer --port=80

# Get the external IP
kubectl get svc myapp

# Access the service (from cluster network)
curl http://<EXTERNAL-IP>
```

## 🔧 Manual Provisioning

### Step 1: Deploy Infrastructure
```bash
cd hetzner/terraform
export BWS_ACCESS_TOKEN="your-token"
bws run --project-id YOUR_PROJECT_ID tofu apply
```

### Step 2: Provision Master
```bash
# SSH to master
ssh root@<master-ip>

# Set vars
export HETZNER_API_TOKEN="token"
export HETZNER_NETWORK_ID="<from terraform output>"
export MASTER_PRIVATE_IP="10.200.40.11"

# Run script
bash provision-master.sh
```

### Step 3: Provision Workers
```bash
# Get join command from master
ssh root@<master-ip> cat /root/kubeadm-join-command.sh

# SSH to each worker
ssh root@<worker-ip>

# Set join command and run
export JOIN_COMMAND="kubeadm join ..."
bash provision-worker.sh
```

### Step 4: Deploy MetalLB
```bash
# From master or with kubeconfig
bash deploy-metallb.sh
```

## 🌐 Networks

- **Cluster Network**: `10.200.40.0/24` - Internal node communication
- **Ingress Network**: `10.100.40.0/24` - MetalLB LoadBalancer IPs
- **Pod Network**: `10.244.0.0/16` - Flannel CNI
- **LoadBalancer Pool**: `10.100.40.100-200` - Available IPs for services

## 📊 Architecture

```
Internet → Public IPs → Nodes
                         ├─ Cluster Network (10.200.40.0/24)
                         ├─ Ingress Network (10.100.40.0/24) ← MetalLB
                         └─ Pod Network (10.244.0.0/16)
```

## 🔍 Troubleshooting

```bash
# Check node status
kubectl get nodes -o wide

# Check all pods
kubectl get pods -A

# Check specific namespace
kubectl get pods -n metallb-system

# Describe a node
kubectl describe node server1

# Check kubelet logs on a node
ssh root@<node-ip> journalctl -u kubelet -f

# Check MetalLB logs
kubectl logs -n metallb-system -l component=speaker
kubectl logs -n metallb-system -l component=controller
```

## 🧹 Cleanup

```bash
# Destroy entire cluster
./cluster-helper.sh destroy

# Or manually
cd terraform/
tofu destroy
```

## 📝 Files Overview

- `provision-master.sh` - Master node setup script
- `provision-worker.sh` - Worker node setup script
- `deploy-metallb.sh` - MetalLB installation
- `deploy-cluster.sh` - Full automated deployment
- `cluster-helper.sh` - Management utilities
- `cloud-init-master.yml` - Master cloud-init template
- `cloud-init-worker.yml` - Worker cloud-init template

## ⚙️ Configuration

Edit these in the scripts as needed:
- Kubernetes version: `KUBE_VERSION="v1.31.0"`
- MetalLB version: `METALLB_VERSION="v0.14.8"`
- IP ranges: Update in scripts and Terraform
- Firewall rules: Update in `main.tf`

## 🔐 Security Notes

1. Store secrets in Bitwarden
2. Use SSH keys (no passwords)
3. Restrict firewall to needed ports only
4. Enable RBAC in production
5. Use network policies
6. Rotate tokens regularly

## 📚 More Info

See `PROVISIONING.md` for detailed documentation.
