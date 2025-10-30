terraform {
  backend "s3" {
    # Dont forget to set these environment variables:
    #  export AWS_ACCESS_KEY_ID="YOUR_HETZNER_ACCESS_KEY"
    #  export AWS_SECRET_ACCESS_KEY="YOUR_HETZNER_SECRET_KEY"
    #  export AWS_DEFAULT_REGION="eu-central"
    bucket = "slickg"
    key    = "homelab/hetzner/terraform/terraform.tfstate"
    #region         = "eu-central"  # or any placeholder (Hetzner ignores this)
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
  }
}

#Bitwarden related configs
variable "bw_access_token" {
  description = "Bitwarden Access Token"
  type        = string
  sensitive   = true
}
provider "bitwarden-secrets" {
  access_token = var.bw_access_token
}
data "bitwarden-secrets_secret" "HETZER_API_TOKEN" {
  id = "5cc33b68-00c5-41c1-9249-b36b00b04efd"
}
data "bitwarden-secrets_secret" "epam_ssh_key" {
  id = "25e9088e-bee2-4611-9f55-b36e0081c719"
}
data "bitwarden-secrets_secret" "mac_air_ssh_key" {
  id = "3ec83a77-da6c-46c5-a151-b38600efd66b"
}

data "bitwarden-secrets_secret" "cloud_inits" {
  for_each = { for node in var.node_configs : node.name => node.cloud_init_id }
  id       = each.value
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
      name                    = "server1"
      cloud_init_id           = "9f7efe03-5bf4-42a1-aaca-b36e00a7b177"
      node_internal_ip        = "10.200.40.11"
      node_cluster_ingress_ip = "10.100.40.11"
      firewall_group          = "only-web-inbound"
    },

    {
      name                    = "agent1"
      cloud_init_id           = "c2d9f592-d9b9-449d-879b-b36e00a80234"
      node_internal_ip        = "10.200.40.21"
      node_cluster_ingress_ip = "10.100.40.21"
      firewall_group          = "block-all-inbound"
    },
    {
      name                    = "agent2"
      cloud_init_id           = "a3cc5397-d98c-42a0-9c9c-b36e00a8197c"
      node_internal_ip        = "10.200.40.22"
      node_cluster_ingress_ip = "10.100.40.22"
      firewall_group          = "block-all-inbound"
    },
    {
      name                    = "agent3"
      cloud_init_id           = "f4f53e3b-a460-4c86-9510-b36e00a82def"
      node_internal_ip        = "10.200.40.23"
      node_cluster_ingress_ip = "10.100.40.23"
      firewall_group          = "block-all-inbound"
    },
  ]
}
variable "firewalls" {
  default = {
    "only-web-inbound" = [
      {
        direction  = "in"
        protocol   = "icmp"
        port       = null
        source_ips = ["0.0.0.0/0", "::/0"]
      },
      {
        direction  = "in"
        protocol   = "tcp"
        port       = "80"
        source_ips = ["0.0.0.0/0", "::/0"]
      },
      {
        direction  = "in"
        protocol   = "tcp"
        port       = "443"
        source_ips = ["0.0.0.0/0", "::/0"]
      },
    ]
    "block-all-inbound" = []
  }
}
resource "hcloud_firewall" "dynamic_firewalls" {
  for_each = var.firewalls

  name = each.key

  dynamic "rule" {
    for_each = each.value
    content {
      direction  = rule.value.direction
      protocol   = rule.value.protocol
      port       = rule.value.port
      source_ips = rule.value.source_ips
    }
  }
}
resource "hcloud_ssh_key" "main" {
  name       = "epam_ssh_key"
  public_key = data.bitwarden-secrets_secret.epam_ssh_key.value
}
resource "hcloud_ssh_key" "main-extra" {
  name       = "mac_air_ssh_key"
  public_key = data.bitwarden-secrets_secret.mac_air_ssh_key.value
}

resource "hcloud_network" "cluster_network" {
  name     = "cluster-network"
  ip_range = "10.200.40.0/24"
}

resource "hcloud_network" "cluster_ingress_network" {
  name     = "cluster-ingress-network"
  ip_range = "10.100.40.0/24"
}


resource "hcloud_network_subnet" "cluster-net" {
  network_id   = hcloud_network.cluster_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.200.40.0/24"
}

resource "hcloud_network_subnet" "cluster-ingress-net" {
  network_id   = hcloud_network.cluster_ingress_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.100.40.0/24"
}


resource "hcloud_server" "k3s_nodes" {
  for_each    = { for node in var.node_configs : node.name => node }
  name        = each.value.name
  image       = var.image_name
  server_type = var.server_type
  location    = var.location


  user_data = data.bitwarden-secrets_secret.cloud_inits[each.key].value

  firewall_ids = [hcloud_firewall.dynamic_firewalls[each.value.firewall_group].id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.cluster_network.id
    ip         = each.value.node_internal_ip
  }
  network {
    network_id = hcloud_network.cluster_ingress_network.id
    ip         = each.value.node_cluster_ingress_ip
  }
  ssh_keys = [
    hcloud_ssh_key.main.id,
  ]
  depends_on = [
    hcloud_network_subnet.cluster-net,
    hcloud_network_subnet.cluster-ingress-net,
  ]
}
