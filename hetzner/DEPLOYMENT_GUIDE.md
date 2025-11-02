# Hetzner K8s Cluster - Deployment Flow

## 📦 What Was Created

### New Provisioning Scripts
```
scripts/
├── provision-master.sh    ← Master node K8s setup (K8s v1.31, Flannel, Hetzner CCM)
├── provision-worker.sh    ← Worker node K8s setup
├── deploy-metallb.sh      ← MetalLB LoadBalancer deployment
├── deploy-cluster.sh      ← Full automated deployment orchestrator
└── cluster-helper.sh      ← Management utility commands
```

### New Configuration Files
```
terraform/
├── cloud-init-master.yml  ← Cloud-init template for master
├── cloud-init-worker.yml  ← Cloud-init template for workers
└── PROVISIONING.md        ← Detailed deployment documentation
```

### New Documentation
```
├── README.md              ← Main project documentation
├── QUICKSTART.md          ← Quick command reference
└── Makefile               ← Convenient make targets
```

## 🔄 Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Terraform Infrastructure                            │
├─────────────────────────────────────────────────────────────┤
│ make apply                                                   │
│   ↓                                                          │
│ Creates:                                                     │
│   • 4 Hetzner Cloud servers (1 master + 3 workers)         │
│   • 2 Private networks (cluster + ingress)                  │
│   • Firewalls (master: 80/443, workers: none)              │
│   • SSH keys from Bitwarden                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Master Node Provisioning                            │
├─────────────────────────────────────────────────────────────┤
│ provision-master.sh                                          │
│   ↓                                                          │
│ Installs:                                                    │
│   • Containerd 1.7.22 (container runtime)                   │
│   • Kubernetes v1.31 (kubeadm, kubelet, kubectl)           │
│   • Flannel CNI (pod networking)                            │
│   • Hetzner Cloud Controller Manager                        │
│   • Hetzner CSI Driver (persistent volumes)                 │
│   ↓                                                          │
│ Initializes:                                                 │
│   • K8s control plane (kubeadm init)                        │
│   • Pod network (10.244.0.0/16)                             │
│   • Cluster network (10.200.40.0/24)                        │
│   ↓                                                          │
│ Generates:                                                   │
│   • /root/kubeadm-join-command.sh                           │
│   • /etc/kubernetes/admin.conf                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Worker Nodes Provisioning                           │
├─────────────────────────────────────────────────────────────┤
│ provision-worker.sh (on each worker)                         │
│   ↓                                                          │
│ Installs:                                                    │
│   • Containerd 1.7.22                                       │
│   • Kubernetes v1.31 components                             │
│   ↓                                                          │
│ Joins cluster:                                               │
│   • Uses join command from master                           │
│   • Connects to control plane                               │
│   • Registers as worker node                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: MetalLB Deployment                                  │
├─────────────────────────────────────────────────────────────┤
│ deploy-metallb.sh                                            │
│   ↓                                                          │
│ Deploys:                                                     │
│   • MetalLB v0.14.8 (controller + speaker pods)            │
│   ↓                                                          │
│ Configures:                                                  │
│   • IP Address Pool: 10.100.40.100-200                     │
│   • L2 Advertisement on ingress network                     │
│   • Auto-assignment enabled                                 │
│   ↓                                                          │
│ Result:                                                      │
│   • LoadBalancer services get IPs from pool                 │
│   • Services accessible on ingress network                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: Cluster Ready! 🎉                                   │
├─────────────────────────────────────────────────────────────┤
│ • 4 nodes (1 master + 3 workers) ✓                          │
│ • Flannel CNI operational ✓                                 │
│ • MetalLB LoadBalancer ready ✓                              │
│ • Hetzner Cloud integration ✓                               │
│ • Ready to deploy applications ✓                            │
└─────────────────────────────────────────────────────────────┘
```

## 🌐 Network Architecture

```
                      ┌─────────────────┐
                      │   Internet      │
                      └────────┬────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
         ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
         │ server1 │     │ agent1  │     │ agent2  │
         │ MASTER  │     │ WORKER  │     │ WORKER  │
         │         │     │         │     │         │
         │ Public  │     │ Public  │     │ Public  │
         │   IP    │     │   IP    │     │   IP    │
         └────┬────┘     └────┬────┘     └────┬────┘
              │               │               │
              └───────────────┼───────────────┘
                              │
         ┌────────────────────┴────────────────────┐
         │                                         │
    ┌────▼──────────────────┐      ┌──────────────▼──────────┐
    │ Cluster Network       │      │ Ingress Network         │
    │ 10.200.40.0/24        │      │ 10.100.40.0/24          │
    │                       │      │                         │
    │ • .11  = master       │      │ • .11  = master         │
    │ • .21  = agent1       │      │ • .21  = agent1         │
    │ • .22  = agent2       │      │ • .22  = agent2         │
    │ • .23  = agent3       │      │ • .23  = agent3         │
    │                       │      │ • .100-.200 = MetalLB   │
    │ Used for:             │      │                         │
    │ - Node communication  │      │ Used for:               │
    │ - Kubelet traffic     │      │ - LoadBalancer IPs      │
    │ - Internal services   │      │ - External service      │
    │                       │      │   access                │
    └───────────────────────┘      └─────────────────────────┘
                │
       ┌────────▼─────────┐
       │  Pod Network     │
       │  10.244.0.0/16   │
       │                  │
       │ • Flannel CNI    │
       │ • Pod-to-pod     │
       └──────────────────┘
```

## 🎯 Usage Examples

### Deploy Full Cluster
```bash
# One command deployment
make quick-deploy

# Or step by step
make apply              # 1. Create infrastructure
make deploy             # 2. Deploy K8s + MetalLB
make kubeconfig         # 3. Get kubeconfig
export KUBECONFIG=~/.kube/config-hetzner
make status             # 4. Check status
```

### Deploy a Web App with LoadBalancer
```bash
# Deploy nginx
kubectl create deployment web --image=nginx

# Expose with LoadBalancer (MetalLB assigns IP automatically)
kubectl expose deployment web --type=LoadBalancer --port=80

# Check the assigned IP (from 10.100.40.100-200 range)
kubectl get svc web

# Example output:
# NAME   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
# web    LoadBalancer   10.43.123.45    10.100.40.105   80:31234/TCP
```

### Test LoadBalancer
```bash
# Quick test
make test-lb

# Access from master node (ingress network is accessible)
make ssh-master
curl http://10.100.40.105  # Use the IP from above
```

### Management Commands
```bash
# Check cluster
make status              # Full status
make nodes               # Just nodes
make pods                # All pods
make services            # All services

# MetalLB specific
make metallb-status      # MetalLB health
make endpoints           # All LB endpoints

# Access nodes
make ssh-master          # SSH to master
make ssh-agent1          # SSH to worker
make logs-master         # View logs
```

## 🔧 How MetalLB Works

```
┌──────────────────────────────────────────────────────────┐
│ When you create a LoadBalancer Service:                 │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  kubectl expose deployment app --type=LoadBalancer      │
│                    ↓                                     │
│  MetalLB Controller sees the service                    │
│                    ↓                                     │
│  Assigns IP from pool (10.100.40.100-200)              │
│                    ↓                                     │
│  Updates service with EXTERNAL-IP                       │
│                    ↓                                     │
│  MetalLB Speaker announces IP via L2 (ARP)             │
│                    ↓                                     │
│  Traffic to that IP routes to the service               │
└──────────────────────────────────────────────────────────┘

Example:
  Service: my-web
  Type: LoadBalancer
  Assigned IP: 10.100.40.105
  
  → Access at http://10.100.40.105
  → MetalLB routes to service pods
  → Works within ingress network (10.100.40.0/24)
```

## 📊 Component Status Check

```bash
# After deployment, verify everything:

# 1. Nodes should be Ready
kubectl get nodes
# NAME      STATUS   ROLES           AGE   VERSION
# server1   Ready    control-plane   10m   v1.31.0
# agent1    Ready    <none>          8m    v1.31.0
# agent2    Ready    <none>          8m    v1.31.0
# agent3    Ready    <none>          8m    v1.31.0

# 2. System pods should be Running
kubectl get pods -n kube-system
# coredns, kube-proxy, hcloud-ccm, etc.

# 3. Flannel should be Running
kubectl get pods -n kube-flannel

# 4. MetalLB should be Running
kubectl get pods -n metallb-system
# controller-xxx, speaker-xxx (one per node)

# 5. IP pool configured
kubectl get ipaddresspool -n metallb-system
# NAME                   AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
# hetzner-ingress-pool   true          false             ["10.100.40.100-10.100.40.200"]
```

## 🎓 Key Concepts

### Why Two Networks?

1. **Cluster Network (10.200.40.0/24)**
   - Internal Kubernetes communication
   - Node-to-node traffic
   - Not exposed externally

2. **Ingress Network (10.100.40.0/24)**
   - MetalLB LoadBalancer IPs
   - External service access
   - Dedicated for ingress traffic

### MetalLB Layer 2 Mode

- Uses ARP to announce IPs
- Simple, no BGP required
- Works on any network
- IP is "claimed" by one node (speaker)
- Traffic goes to that node, then routed to pods

### Hetzner Integration

- **CCM** (Cloud Controller Manager): Manages nodes, routes
- **CSI** (Container Storage Interface): Provides volumes
- Both use Hetzner API (token from Bitwarden)

## 🎉 Success Indicators

After deployment, you should see:

✅ All 4 nodes in Ready state
✅ All system pods Running
✅ Flannel pods on each node
✅ MetalLB controller + speakers Running
✅ Can create LoadBalancer services
✅ Services get IPs from 10.100.40.100-200
✅ Can access services from ingress network

## 🚨 Common Issues

### Nodes Not Ready
- Check kubelet: `make ssh-master` → `journalctl -u kubelet -f`
- Check CNI: `kubectl get pods -n kube-flannel`

### MetalLB Not Assigning IPs
- Check speaker logs: `kubectl logs -n metallb-system -l component=speaker`
- Verify pool: `kubectl get ipaddresspool -n metallb-system`

### Can't Access LoadBalancer
- IPs are on ingress network (10.100.40.0/24)
- Test from master node, not from outside
- Check service endpoints: `kubectl get endpoints <service-name>`

## 📚 Next Steps

1. **Setup Ingress Controller**
   - Nginx Ingress or Traefik
   - Will get a LoadBalancer IP from MetalLB
   - Route HTTP/HTTPS traffic to services

2. **Configure DNS**
   - Point domain to LoadBalancer IP
   - Use external DNS or Cloudflare

3. **Add Cert-Manager**
   - Automatic TLS certificates
   - Let's Encrypt integration

4. **Deploy Your Apps**
   - Use the cluster for real workloads!

---

**Created by:** Homelab K8s Provisioning Scripts
**Purpose:** Production-ready K8s cluster on Hetzner Cloud
**Features:** MetalLB, Hetzner integration, automated deployment
