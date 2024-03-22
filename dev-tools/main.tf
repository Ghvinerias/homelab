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
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    nds = {
      source  = "peknur/nds"
      version = "0.3.0"
    }
  }
}
resource "random_password" "tunnel_secret" {
  length = 64
}
resource "cloudflare_tunnel" "auto_tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.lxc_hostname
  secret     = base64sha256(random_password.tunnel_secret.result)
}
resource "docker_image" "cloudflared" {
  name = "cloudflare/cloudflared:latest"
}
resource "docker_container" "cloudflared" {
  image    = docker_image.cloudflared.image_id
  name     = "cloudflared"
  hostname = "cloudflared"
  restart  = "unless-stopped"
  upload {
    executable = false
    file       = "/tmp/credentials.yml"
    content    = jsonencode({ "AccountTag" = var.cloudflare_account_id, "TunnelSecret" = base64sha256(random_password.tunnel_secret.result), "TunnelID" = cloudflare_tunnel.auto_tunnel.id })
  }
  command = ["tunnel", "run", "--credentials-file", "/tmp/credentials.yml", "var.lxc_hostname"]
  networks_advanced {
    name = docker_network.private_network.id
  }
}

resource "docker_network" "private_network" {
  name   = "my_network"
  driver = "bridge"
}

resource "docker_image" "it-tools" {
  name = "corentinth/it-tools:latest"
}
resource "docker_container" "it-tools" {
  image    = docker_image.it-tools.image_id
  name     = "it-tools"
  hostname = "it-tools"
  restart  = "unless-stopped"
  networks_advanced {
    name = docker_network.private_network.id
  }
}
resource "cloudflare_record" "ittools" {
  zone_id = var.cloudflare_zone_id
  name    = "ittools"
  value   = cloudflare_tunnel.auto_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "docker_image" "echo" {
  name = "mendhak/http-https-echo:31"
}
resource "docker_container" "echo" {
  image    = docker_image.echo.image_id
  name     = "echo"
  hostname = "echo"
  restart  = "unless-stopped"
  env = [
    "HTTP_PORT=8880"
  ]
  networks_advanced {
    name = docker_network.private_network.id
  }
}
resource "cloudflare_record" "echo" {
  zone_id = var.cloudflare_zone_id
  name    = "echo"
  value   = cloudflare_tunnel.auto_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_tunnel_config" "auto_tunnel" {
  tunnel_id  = cloudflare_tunnel.auto_tunnel.id
  account_id = var.cloudflare_account_id
  config {
    ingress_rule {
      hostname = cloudflare_record.ittools.hostname
      service  = "http://it-tools:80"
    }
    ingress_rule {
      hostname = cloudflare_record.echo.hostname
      service  = "http://echo:8880"
    }
    ingress_rule {
      hostname = cloudflare_record.echo.hostname
      service  = "http://jupyter:8080 "
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}


resource "docker_image" "jupyter" {
  name = "jupyter/minimal-notebook"
}
resource "docker_container" "jupyter" {
  image    = docker_image.echo.image_id
  name     = "jupyter"
  hostname = "jupyter"
  restart  = "unless-stopped"
  networks_advanced {
    name = docker_network.private_network.id
  }
}
resource "cloudflare_record" "jupyter" {
  zone_id = var.cloudflare_zone_id
  name    = "jupyter"
  value   = cloudflare_tunnel.auto_tunnel.cname
  type    = "CNAME"
  proxied = true
}