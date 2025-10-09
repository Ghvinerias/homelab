'''
helm repo add ingress-nginx <https://kubernetes.github.io/ingress-nginx>
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
--namespace ingress-nginx --create-namespace
'''

'''
helm repo add jetstack <https://charts.jetstack.io>
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.12.1 \
  --set installCRDs=true \
  --set global.leaderElection.namespace=cert-manager
'''
'''
kubectl apply -f ./letsencrypt-dev.yaml
'''

'''
kubectl create namespace example-app
'''

'''
kubectl apply -f ./example-app-deployment.yaml
kubectl apply -f ./example-app-ingress.yaml
'''
