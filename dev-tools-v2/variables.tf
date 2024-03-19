variable "lxc_hostname" {
  description = "LXC Container Hostname"
  type        = string
  default     = "lxc-docker"
}
variable "lxc_memory" {
  description = "LXC Container RAM"
  type        = string
  default     = "512"
  validation {
    condition = contains([
      "512",
      "1024",
      "2048",
      "3072",
      "4098"
    ], var.lxc_memory)
    error_message = "Invalid memory value."
  }
}
variable "lxc_cores" {
  description = "LXC Container CPU Core Count"
  type        = number
  default     = "1"
  validation {
    condition = (
      var.lxc_cores >= 1 &&
      var.lxc_cores <= 4
    )
    error_message = "Disk size must be integer between 5 and 100 (GB)."
  }
}
variable "lxc_disk_size" {
  description = "LXC Container Disk Size"
  default     = 10
  validation {
    condition = (
      var.lxc_disk_size >= 10 &&
      var.lxc_disk_size <= 100
    )
    error_message = "Disk size must be integer between 5 and 100 (GB)."
  }
}

variable "cloudflare_zone" {
  description = "LXC Container Hostname"
  type        = string
}
variable "cloudflare_zone_id" {
  description = "LXC Container Hostname"
  type        = string
}
variable "cloudflare_account_id" {
  description = "LXC Container Hostname"
  type        = string
}
variable "cloudflare_email" {
  description = "LXC Container Hostname"
  type        = string
}
variable "cloudflare_token" {
  description = "LXC Container Hostname"
  type        = string
  default     = "slick.ge"
}
variable "pm_api" {
  description = "LXC Container Hostname"
  type        = string
}
variable "pm_user" {
  description = "LXC Container Hostname"
  type        = string
}
variable "pm_token" {
  description = "LXC Container Hostname"
  type        = string
}