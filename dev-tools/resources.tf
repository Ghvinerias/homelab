provider "cloudflare" {
  api_key = var.cloudflare_token
  email   = var.cloudflare_email
}
provider "random" {
}
provider "docker" {
  host = "tcp://${var.lxc_hostname}:2375"
}

# provider "docker" {
#   host     = "ssh://user@remote-host:22"
#   ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
# }