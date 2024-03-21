terraform {
  required_version = ">= 0.13"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}
resource "proxmox_lxc" "dev-environment" {
  for_each        = var.lxc_hosts
  bwlimit         = 0
  force           = false
  target_node     = "pve"
  hostname        = each.key
  ostemplate      = "local:vztmpl/slick-ubuntu-22.04-docker.tar.gz"
  unprivileged    = true
  cores           = each.value.lxc_cores
  memory          = each.value.lxc_memory
  start           = true
  onboot          = true
  ssh_public_keys = <<-EOT
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1wCTpWRfuTb/w/2ySOVLX/Naq8jlWrmAW03sUHKjqEVSpjJvMqP1HCBT2cuSOCnlPctF22eqoC2A5f171ASUwRJWB8qwmska5D+Rf/lA2+H46JPQBi5TxtQRSh4mbiODqbRBHwkfRpywF1lFGsd+CsSCOL7TGwjEP/GyMS4bC2pk1YUcz43kyEO3/pD0TqRrg16n3b/Loy/XvQXArNf6slxjV4A0v7yQBm+z7AgibdUK2rt7V3kRVyh3boAjDngsM6hdIPepOBcJeYbOG3mP5896yKDlmJ0IIDnJ88ilWOFI5YivPN89iYxqIuyw1+JBtsSuHSMBc4g6CtPZ2D0VoS2S5FR5fE9C1lbgdDXUEgq/kxP/htDIljSBKlpHnrhZXXwESyLGWyvnSrjeN92+V6JIP3f/QRhISLEFzWEkC/MNwxdompZ63C9PZUkP74d4eZLNrIYYwEndfSQsdYpRxC7Gi9SiMqkandLiGw5DX3HIvgupDgfK7gSKC9x5FYNc= root@code-server
  EOT
  features {
    fuse    = true
    nesting = true
  }
  rootfs {
    storage = "local-lvm"
    size    = "${each.value.lxc_disk_size}G"
  }
  nameserver   = "10.10.10.1"
  searchdomain = "slick.ge"
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    tag    = "0"
  }
}
