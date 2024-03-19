terraform {
  required_version = ">= 0.13"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.9.0"
    }
    random = {
      source = "hashicorp/random"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.4"
    }
  }
}

resource "random_password" "tunnel_secret" {
  length = 64
}
# Creates a new locally-managed tunnel for the GCP VM.
resource "cloudflare_tunnel" "auto_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "Terraform GCP tunnel"
  secret     = base64sha256(random_password.tunnel_secret.result)
}

# Creates the CNAME record that routes http_app.${var.cloudflare_zone} to the tunnel.
resource "cloudflare_record" "http_app" {
  zone_id = var.cloudflare_zone_id
  name    = "http_app"
  value   = cloudflare_tunnel.auto_tunnel.cname
  type    = "CNAME"
  proxied = true
}

# Creates the configuration for the tunnel.
resource "cloudflare_tunnel_config" "auto_tunnel" {
  tunnel_id  = cloudflare_tunnel.auto_tunnel.id
  account_id = var.cloudflare_account_id
  config {
    ingress_rule {
      hostname = cloudflare_record.http_app.hostname
      service  = "http://it-tools:8888"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "proxmox_lxc" "advanced_features" {
  target_node  = "pve"
  hostname     = var.lxc_hostname
  ostemplate   = "local:vztmpl/slick-ubuntu-22.04-docker.tar.gz"
  unprivileged = true
  cores        = var.lxc_cores
  memory       = var.lxc_memory
  start        = true

  ssh_public_keys = <<-EOT
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1wCTpWRfuTb/w/2ySOVLX/Naq8jlWrmAW03sUHKjqEVSpjJvMqP1HCBT2cuSOCnlPctF22eqoC2A5f171ASUwRJWB8qwmska5D+Rf/lA2+H46JPQBi5TxtQRSh4mbiODqbRBHwkfRpywF1lFGsd+CsSCOL7TGwjEP/GyMS4bC2pk1YUcz43kyEO3/pD0TqRrg16n3b/Loy/XvQXArNf6slxjV4A0v7yQBm+z7AgibdUK2rt7V3kRVyh3boAjDngsM6hdIPepOBcJeYbOG3mP5896yKDlmJ0IIDnJ88ilWOFI5YivPN89iYxqIuyw1+JBtsSuHSMBc4g6CtPZ2D0VoS2S5FR5fE9C1lbgdDXUEgq/kxP/htDIljSBKlpHnrhZXXwESyLGWyvnSrjeN92+V6JIP3f/QRhISLEFzWEkC/MNwxdompZ63C9PZUkP74d4eZLNrIYYwEndfSQsdYpRxC7Gi9SiMqkandLiGw5DX3HIvgupDgfK7gSKC9x5FYNc= root@code-server
  EOT

  features {
    fuse    = true
    nesting = true
  }

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-lvm"
    size    = "${var.lxc_disk_size}G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr420"
    ip     = "dhcp"
    tag    = "20"
  }
  connection {
    type     = "ssh"
    user     = "root"
    host     = var.lxc_hostname
    password = var.pm_token
    //    private_key = file("/root/.ssh/id_rsa")
  }
  provisioner "file" {
    source      = "docker-compose.tftpl"
    destination = "/root/docker-compose.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "docker-compose up -d",
    ]
  }

}



