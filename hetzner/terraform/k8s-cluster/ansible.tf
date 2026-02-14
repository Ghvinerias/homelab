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

# resource "null_resource" "install_default_resources" {

#   depends_on = [
#     null_resource.install_and_provision_K8S_Cluster,
#   ]

#   provisioner "local-exec" {
#     working_dir = "/Users/aleksandre_ghvineria/Code/homelab/hetzner/Ansible"
#     command     = "ansible-playbook -i inventory.ini preconfig-k8s.yml"
#   }
# }

# resource "null_resource" "deploy_bitwarden_secrets_operator" {

#   depends_on = [
#     null_resource.install_default_resources,
#   ]

#   provisioner "local-exec" {
#     working_dir = "/Users/aleksandre_ghvineria/Code/homelab/hetzner/Ansible"
#     command     = "ansible-playbook -i inventory.ini deploy-bitwarden-operator.yml -e bw_token=${data.bitwarden-secrets_secret.k8s_bsm_operator_token.value}"
#   }
# }

# resource "null_resource" "deploy_longhorn_storage" {

#   depends_on = [
#     null_resource.deploy_bitwarden_secrets_operator,
#   ]

#   provisioner "local-exec" {
#     working_dir = "/Users/aleksandre_ghvineria/Code/homelab/hetzner/Ansible"
#     command     = "ansible-playbook -i inventory.ini deploy-longhorn.yml"
#   }
# }

# resource "null_resource" "deploy_portainer" {

#   depends_on = [
#     null_resource.deploy_longhorn_storage,
#   ]

#   provisioner "local-exec" {
#     working_dir = "/Users/aleksandre_ghvineria/Code/homelab/hetzner/Ansible"
#     command     = "ansible-playbook -i inventory.ini deploy-portainer.yml"
#   }
# }