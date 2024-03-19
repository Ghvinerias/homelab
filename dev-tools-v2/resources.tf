provider "cloudflare" {
  api_key = var.cloudflare_token
  email = var.cloudflare_email
}
provider "random" {
}
provider "proxmox" {
  pm_api_url      = var.pm_api
  pm_user         = var.pm_user
  pm_password     = var.pm_token
  pm_tls_insecure = true
  # For debugging Terraform provider errors:
  pm_debug      = true
  pm_log_enable = true
  pm_log_file   = "/var/log/terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}