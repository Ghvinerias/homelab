variable "bw_access_token" {
  description = "Bitwarden Access Token"
  type        = string
  sensitive   = true
}
provider "bitwarden-secrets" {
  access_token = var.bw_access_token
}
data "bitwarden-secrets_secret" "CF_API_TOKEN" {
  id = "c1c26bbe-2a12-451f-a5f6-b37f00c90206"
}
data "bitwarden-secrets_secret" "CF_EMAIL_ROUTE_DESTINATION" {
  id = "dd8c35f5-ce4a-4143-984d-b37f0126b93c"
}
data "bitwarden-secrets_secret" "c1f9a7ac7334dd09ff3b37f01405646" {
  id = "9c1f9a7a-c733-4dd0-9ff3-b37f01405646"
}
data "bitwarden-secrets_secret" "e9ad442b7cc74ff3ac2eb37f0149aa86" {
  id = "e9ad442b-7cc7-4ff3-ac2e-b37f0149aa86"
}
data "bitwarden-secrets_secret" "de90cdad7bec475eb4b0b37f014a0e08" {
  id = "de90cdad-7bec-475e-b4b0-b37f014a0e08"
}
data "bitwarden-secrets_secret" "a5a474ff3f14024b2abb37f014a5e4a" {
  id = "4a5a474f-f3f1-4024-b2ab-b37f014a5e4a"
}
data "bitwarden-secrets_secret" "c0e1aee9e9e248949fefb37f014ac468" {
  id = "c0e1aee9-e9e2-4894-9fef-b37f014ac468"
}
data "bitwarden-secrets_secret" "fd4c1a3f3142db8385b37f014b1aa7" {
  id = "20fd4c1a-3f31-42db-8385-b37f014b1aa7"
}
data "bitwarden-secrets_secret" "d8cf1c43be5a4e8ebfdfb37f014b9281" {
  id = "d8cf1c43-be5a-4e8e-bfdf-b37f014b9281"
}
data "bitwarden-secrets_secret" "fa674bfb94baf8edcb37f014c1579" {
  id = "512fa674-bfb9-4baf-8edc-b37f014c1579"
}
