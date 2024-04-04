variable "cloudflare_zone" {
  description = "CloudFlare Zone"
  type        = string
}
variable "cloudflare_zone_id" {
  description = "CloudFlare Zone ID"
  type        = string
}
variable "cloudflare_account_id" {
  description = "CloudFlare Account ID"
  type        = string
}
variable "cloudflare_email" {
  description = "CloudFlare Account Email"
  type        = string
}
variable "cloudflare_token" {
  description = "CloudFlare Account Token"
  type        = string
  sensitive   = true
}
variable "lxc_hostname" {
  description = "LXC Container Hostname"
  type        = string
}
variable "tf_cloud_ssh_private_key" {
  type        = string
  description = "(optional) Private SSH key defined as a workspace variable in Terraform cloud"
  default     = null
  sensitive   = true
}