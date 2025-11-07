########################
# Ansible Integration  #
########################

resource "null_resource" "install_and_provision_K8S_Cluster" {

  depends_on = [
    hcloud_server.k8s_nodes,
  ]

  # Re-run when node configuration changes (e.g., node added/removed/modified)
  # Using a hash of var.node_configs ensures this resource is replaced when the
  # cluster topology changes, triggering the local-exec provisioner again.
  triggers = {
    nodes_hash  = sha1(jsonencode(var.node_configs))
    nodes_count = tostring(length(var.node_configs))
  }

  provisioner "local-exec" {
    working_dir = "/Users/aleksandre_ghvineria/Code/homelab/hetzner/Ansible"
    command     = "ansible-playbook -i inventory.ini provision-cluster.yml -e setup_local_kubeconfig=true"
  }
}

resource "null_resource" "provision_k8s_resources" {

  depends_on = [
    null_resource.install_and_provision_K8S_Cluster,
  ]

  provisioner "local-exec" {
    working_dir = "/Users/aleksandre_ghvineria/Code/homelab/hetzner/Ansible"
    command     = "ansible-playbook -i inventory.ini preconfig-k8s.yml"
  }
}
