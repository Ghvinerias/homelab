terraform {
  backend "s3" {
    # Dont forget to set these environment variables:
    #  export AWS_ACCESS_KEY_ID="YOUR_HETZNER_ACCESS_KEY"
    #  export AWS_SECRET_ACCESS_KEY="YOUR_HETZNER_SECRET_KEY"
    #  export AWS_DEFAULT_REGION="eu-central"
    bucket = "slickg"
    key    = "homelab/hetzner/terraform/terraform.tfstate"
    #region   = "eu-central"                          # Placeholder for Hetzner Object Storage
    endpoint = "https://fsn1.your-objectstorage.com" # Replace with your Hetzner endpoint
    #access_key     = ""
    #secret_key     = ""
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.53.1"
    }
    bitwarden-secrets = {
      source  = "sebastiaan-dev/bitwarden-secrets"
      version = ">=0.1.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
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

#Hetzner Cloud related configs
provider "hcloud" {
  token = data.bitwarden-secrets_secret.HETZER_API_TOKEN.value
}

variable "image_name" {
  description = "The name of the image to use for the cluster nodes."
  type        = string
  default     = "ubuntu-24.04"
}
variable "location" {
  description = "The location where the cluster will be deployed."
  type        = string
  default     = "nbg1"
}
variable "server_type" {
  description = "The type of server to use for the cluster nodes."
  type        = string
  default     = "cx23"
}


variable "node_configs" {
  default = [
    {
      name             = "server1"
      cloud_init_id    = "9f7efe03-5bf4-42a1-aaca-b36e00a7b177"
      node_internal_ip = "10.200.40.11"
      firewall_group   = "only-web-inbound"
    },

    {
      name             = "agent1"
      cloud_init_id    = "c2d9f592-d9b9-449d-879b-b36e00a80234"
      node_internal_ip = "10.200.40.21"
      firewall_group   = "block-all-inbound"
    },
    {
      name             = "agent2"
      cloud_init_id    = "a3cc5397-d98c-42a0-9c9c-b36e00a8197c"
      node_internal_ip = "10.200.40.22"
      firewall_group   = "block-all-inbound"
    },
    {
      name             = "agent3"
      cloud_init_id    = "f4f53e3b-a460-4c86-9510-b36e00a82def"
      node_internal_ip = "10.200.40.23"
      firewall_group   = "block-all-inbound"
    },
  ]
}







resource "hcloud_ssh_key" "main" {
  name       = "epam_ssh_key"
  public_key = data.bitwarden-secrets_secret.epam_ssh_key.value
}
resource "hcloud_ssh_key" "main-extra" {
  name       = "mac_air_ssh_key"
  public_key = data.bitwarden-secrets_secret.mac_air_ssh_key.value
}



resource "hcloud_server" "k3s_nodes" {
  for_each    = { for node in var.node_configs : node.name => node }
  name        = each.value.name
  image       = var.image_name
  server_type = var.server_type
  location    = var.location


  user_data = data.bitwarden-secrets_secret.cloud_inits[each.key].value
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.cluster_network.id
    ip         = each.value.node_internal_ip
  }
  ssh_keys = [
    hcloud_ssh_key.main.id,
    hcloud_ssh_key.main-extra.id,
  ]
}

output "hetzner_public_ips" {
  description = "Map of Hetzner server names to their public IPv4 addresses."
  value       = { for name, s in hcloud_server.k3s_nodes : name => s.ipv4_address }
}


