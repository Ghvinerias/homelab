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
  }
}
data "terraform_remote_state" "cloudflare" {
  backend = "s3"
  config = {
    bucket                      = "slickg"
    key                         = "homelab/cloudflare/slick.ge/terraform.tfstate"
    endpoint                    = "https://fsn1.your-objectstorage.com" # Replace with your Hetzner endpoint
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style = true
  }
}
provider "cloudflare" {
  api_key = data.bitwarden-secrets_secret.CF_API_TOKEN.value
  email   = "ghvineriaa@gmail.com"
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
  default     = "cpx22"
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

locals {
  # Build a list of the cluster nodes' public IPv4 addresses as /32 CIDRs
  cluster_nodes_public_ipv4_cidrs = [for s in values(hcloud_server.k3s_nodes) : "${s.ipv4_address}/32"]
}

resource "hcloud_firewall" "from_server_public_ips" {
  name = "from-servers-public-ips"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = local.cluster_nodes_public_ipv4_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = local.cluster_nodes_public_ipv4_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  depends_on = [
    hcloud_server.k3s_nodes,
  ]
}

resource "hcloud_firewall_attachment" "fw_ref" {
  firewall_id = hcloud_firewall.from_server_public_ips.id
  server_ids  = [for s in hcloud_server.k3s_nodes : s.id]
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

resource "hcloud_network_subnet" "cluster-net" {
  network_id   = hcloud_network.cluster_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.200.40.0/24"
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

# create one A record per Hetzner server's public IP
resource "cloudflare_record" "k8s_node" {
  # Exclude the control-plane node (server1) from public DNS since it does not run ingress
  # and will refuse connections on ports 80/443, which breaks ACME HTTP-01 validation.
  for_each = { for k, v in hcloud_server.k3s_nodes : k => v }
  zone_id  = data.terraform_remote_state.cloudflare.outputs.cloudflare_zone_slick_ge_id
  name     = "k8s.slick.ge"
  type     = "A"
  content  = each.value.ipv4_address
  ttl      = 1
  proxied  = false
}

# record_id: cafd032e3183fbe7415931b0fa462035
resource "cloudflare_record" "k8s_node_wildcard" {
  zone_id = data.terraform_remote_state.cloudflare.outputs.cloudflare_zone_slick_ge_id
  name    = "*.k8s.slick.ge"
  type    = "CNAME"
  content = "k8s.slick.ge"
  ttl     = 1
  proxied = false
}


########################
# Ansible Integration  #
########################



# # Execute Ansible after provisioning. Guarded by var.run_ansible.
resource "null_resource" "run_ansible" {

  depends_on = [
    hcloud_server.k3s_nodes,
  ]

  provisioner "local-exec" {
    working_dir = "/Users/aleksandre_ghvineria/Code/homelab/hetzner/Ansible"
    command     = "ansible-playbook -i inventory.ini provision-cluster-yamp.yml -e setup_local_kubeconfig=true"
  }
}

output "hetzner_public_ips" {
  description = "Map of Hetzner server names to their public IPv4 addresses."
  value       = { for name, s in hcloud_server.k3s_nodes : name => s.ipv4_address }
}
