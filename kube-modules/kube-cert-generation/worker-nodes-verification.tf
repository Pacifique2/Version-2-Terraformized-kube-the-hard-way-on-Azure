#################################################################################
# Verify kube worker nodes
##################################################################################
/*
resource "null_resource" "kube_worker_nodes_verification" {
  #count  = "${var.count}"
  depends_on  = ["null_resource.start_worker_services"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,0)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl get nodes",
    ]
  }
}
*/
################################################################################

