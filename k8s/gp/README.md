# Grafana + Prometheus (kube-prometheus-stack)

This deploys the Prometheus Operator, Prometheus, Grafana, Alertmanager, and exporters via the prometheus-community/kube-prometheus-stack Helm chart into the `monitoring` namespace.

## Prerequisites

- kubectl pointed at your cluster and working
- Helm v3 installed (brew install helm on macOS)
- An Ingress controller (e.g., ingress-nginx) reachable from the Internet if you want external access
- cert-manager with a ClusterIssuer (default expected name here: `letsencrypt-prod`)

If your ClusterIssuer has a different name, update `values.yaml` annotations under each `ingress` section.

## Domains and TLS

Defaults assume k8s.slick.ge subdomains:
- Grafana: `grafana.k8s.slick.ge`
- Prometheus: `prometheus.k8s.slick.ge`
- Alertmanager: `alertmanager.k8s.slick.ge`

Change these in `values.yaml` under the corresponding `ingress.hosts` if needed. TLS secrets are named `*-tls` and will be created by cert-manager if the issuer is present.

## Quick deploy

From the repo root or this folder:

1) Create namespace

```
kubectl apply -f namespace.yaml
```

2) Create Grafana admin credentials (don’t commit these to git)

```
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$(openssl rand -base64 20)" \
  --dry-run=client -o yaml | kubectl apply -f -
```

3) Add Helm repo and install/upgrade

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml
```

4) Check status

```
kubectl -n monitoring get pods,svc,ingress
```

If Ingress and cert-manager are set up, browse to Grafana at https://grafana.k8s.slick.ge and login with the secret you created above.

## Local access (no ingress)

You can port-forward temporarily:

```
# Grafana
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# Alertmanager
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
```

Visit http://localhost:3000 for Grafana; Prometheus at http://localhost:9090.

## Customization tips

- Persistence: If you have Longhorn, set `storageClassName: longhorn` (already configured in `values.yaml`) and tweak sizes. Otherwise leave it unset to use the cluster default.
- Retention: Update `prometheus.prometheusSpec.retention` (default 15d) and storage size.
- Extra scrapes/dashboards: Add your own ServiceMonitors/PodMonitors in any namespace. The chart selectors are open (`{}`) by default.

## Uninstall

```
helm -n monitoring uninstall kube-prometheus-stack
kubectl delete -f namespace.yaml
```

Note: Deleting the namespace removes all resources (including PVCs) in it.
