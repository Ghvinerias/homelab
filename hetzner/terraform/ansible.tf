########################
# Ansible Integration  #
########################

resource "null_resource" "install_and_provision_K8S_Cluster" {

  depends_on = [
    hcloud_server.k3s_nodes,
  ]

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
