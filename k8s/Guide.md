
## Add Helm repos for NGINX Ingress Controller and Cert-Manager
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
```

## Update Helm repos
```bash
helm repo update
```

## Install NGINX Ingress Controller with monitoring Disabled
```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace -f ./nle/ingress-nginx-monitoring-values.yaml
```

## Check listener IPs on Nodes
```bash
kubectl -n ingress-nginx get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,HOSTIP:.status.hostIP,PHASE:.status.phase
```

## Use this command to check if nginx is listening on all nodes on port 80
```bash
kubectl -n ingress-nginx get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,HOSTIP:.status.hostIP,PHASE:.status.phase --no-headers | awk '{print $3}' | sort -u | while read ip; do echo "== $ip =="; curl -sSI "http://$ip/" | head -n 1 || true; done
```

## Use this command to check if nginx is listening on all nodes on port 443
```bash
kubectl -n ingress-nginx get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,HOSTIP:.status.hostIP,PHASE:.status.phase --no-headers | awk '{print $3}' | sort -u | while read ip; do echo "== $ip =="; curl -sSI -k "http://$ip/" | head -n 1 || true; done
```

## Install Cert-Manager with CRDs enabled
```bash
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
```

```bash
kubectl apply -f ./nle/cluster-issuer.yaml -n cert-manager
```


### Install Longhorn

# Add the Longhorn Helm chart repository
```bash
helm repo add longhorn https://charts.longhorn.io
```
# Refresh local Helm chart index
```bash
helm repo update
```

# Install or upgrade the Longhorn chart into the `longhorn-system` namespace.
# --install: create release if missing, --upgrade: upgrade if exists
# --create-namespace: create namespace if it doesn't already exist
```bash
helm upgrade --install longhorn longhorn/longhorn \
    --namespace longhorn-system --create-namespace
```

Notes:
- Ensure your kubectl context targets the desired cluster before running these commands.
- To preview the install without applying changes: add `--dry-run=client --debug`.
- Verify deployment: `kubectl -n longhorn-system get pods` and check chart release with `helm status longhorn -n longhorn-system`.




## Helpfull commands

# List cert-manager resources (Certificates, Orders, Challenges) across all namespaces.
```bash
kubectl get certificate,order,challenge -A
```
- Purpose: verify ACME/cert-manager state for issued certificates and in-progress/failed challenges/orders.
- Notes:
    - -A = all namespaces; replace with `-n <namespace>` to scope a single namespace.
    - Inspect details with `kubectl describe <resource> <name> -n <ns>` or `kubectl get <resource> -n <ns> -o yaml`.
    - Useful for troubleshooting failed issuance (look for failed Order/Challenge status and messages).

# Show Pods, Services and Ingresses across all namespaces.
```bash
kubectl get pods,svc,ingress -A
```
- Purpose: quick cluster-wide overview of workload health, service endpoints, and ingress resources.
- Notes:
    - Use `-o wide` for node/IP details or `-n <namespace>` to limit scope.
    - Drill down with `kubectl describe pod/<pod> -n <ns>`, `kubectl describe svc/<svc> -n <ns>`, or `kubectl describe ingress/<ingress> -n <ns>`.
    - Combine with `kubectl logs` for pod-level troubleshooting (e.g., controller or ingress pod logs).
