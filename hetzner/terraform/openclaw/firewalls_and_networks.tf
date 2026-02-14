resource "hcloud_firewall" "from_server_public_ips" {
  name = "from-servers-public-ips"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = local.cluster_nodes_public_ipv4_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = local.cluster_nodes_public_ipv4_cidrs
  }
  depends_on = [
    hcloud_server.openclaw_nodes,
  ]
}

resource "hcloud_firewall_attachment" "fw_ref" {
  firewall_id = hcloud_firewall.from_server_public_ips.id
  server_ids  = [for s in hcloud_server.openclaw_nodes : s.id]
}

resource "hcloud_network" "cluster_network" {
  name     = "cluster-network"
  ip_range = "10.200.41.0/24"
}

resource "hcloud_network_subnet" "cluster-net" {
  network_id   = hcloud_network.cluster_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.200.41.0/24"
}

locals {
  # Build a list of the cluster nodes' public IPv4 addresses as /32 CIDRs
  cluster_nodes_public_ipv4_cidrs = [for s in values(hcloud_server.openclaw_nodes) : "${s.ipv4_address}/32"]
}