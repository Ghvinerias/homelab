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
variable "lxc_hosts" {
  description = "This is a variable of type object"
  type = map(object({
    lxc_memory    = string,
    lxc_cores     = number,
    lxc_disk_size = number
  }))
}