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