
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
data "bitwarden-secrets_secret" "CF_API_TOKEN" {
  id = "c1c26bbe-2a12-451f-a5f6-b37f00c90206"
}
data "bitwarden-secrets_secret" "cloud_inits" {
  for_each = { for node in var.node_configs : node.name => node.cloud_init_id }
  id       = each.value
}
