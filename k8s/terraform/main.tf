terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.1"
    }
  }
}

# --- Inputs ---
variable "kubeconfig" {
  description = "Path to your kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Optional kubeconfig context to target (null uses current-context)"
  type        = string
  default     = null
}

# --- Providers ---
provider "kubernetes" {
  config_path    = var.kubeconfig
  config_context = var.kube_context
}

provider "helm" {
  # Helm provider v3 uses an argument for Kubernetes connection instead of a nested block
  kubernetes = {
    config_path    = var.kubeconfig
    config_context = var.kube_context
  }
}

# --- Locals ---
locals {
  # Paths are relative to this file (k8s/terraform)
  ingress_nginx_values = "${path.module}/../nle/ingress-nginx-monitoring-values.yaml"
  cluster_issuer_yaml  = "${path.module}/../nle/clusterIssuer.yaml"
}

# --- NGINX Ingress Controller ---
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true

  values = [file(local.ingress_nginx_values)]

  wait    = true
  timeout = 600
  atomic  = true
}

# --- cert-manager (with CRDs) ---
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  create_namespace = true

  # Enable CRDs per chart docs
  set = [
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]

  wait    = true
  timeout = 600
  atomic  = true
}

# --- Longhorn ---
resource "helm_release" "longhorn" {
  name             = "longhorn"
  namespace        = "longhorn-system"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  create_namespace = true

  wait    = true
  timeout = 900
  atomic  = true
}

# --- ClusterIssuer (apply existing YAML) ---
# Uses the official kubernetes provider's kubernetes_manifest to apply raw YAML
resource "kubernetes_manifest" "cluster_issuer" {
  # ClusterIssuer is cluster-scoped (namespace omitted/ignored)
  manifest = yamldecode(file(local.cluster_issuer_yaml))

  # Ensure CRDs from cert-manager are installed before applying the ClusterIssuer
  depends_on = [helm_release.cert_manager]
}
