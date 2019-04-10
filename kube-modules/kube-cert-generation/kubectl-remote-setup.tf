

# echo "Setting the kubectl remote user"
resource "null_resource" "kubectl_remote_setup" {
  depends_on  = ["null_resource.kube_api_server_version_test","null_resource.start_worker_services"]
  # "null_resource.kube_worker_nodes_verification"
 /* 
  provisioner "local-exec" {
    command = "sudo chmod +x ${path.module}/scripts/kubernetes-admin-user.sh ${path.module}/scripts/kubectl-verification.sh"
  }
  provisioner "local-exec" {
    command = "sudo cp -r ${path.module}/scripts/kubernetes-admin-user.sh ${path.module}/scripts/kubectl-verification.sh ~/myAzureProject/terraform/azure-k8s-terra-cluster/tls-certs/client-server"
  }
  provisioner "local-exec" {
    command = "cd ~/myAzureProject/terraform/azure-k8s-terra-cluster/tls-certs/client-server"
  } 
  provisioner "local-exec" {
    command =  "./kubernetes-admin-user.sh"
  }
  
  provisioner "local-exec" {  
    command = "cd ~/myAzureProject/terraform/azure-k8s-terra-cluster/tls-certs/client-server && sudo ./kubectl-verification.sh"
  }
  */
  provisioner "local-exec" {
    command =  "echo 'setting up the kubectl remote client'"
    command = "KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g RG-Kube-Free -n RG-Kube-Free-terraform-kubernetes-pip --query ipAddress -otsv)"
    command = "kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443"
    command = "kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem"
    command = "kubectl config set-context kubernetes-the-hard-way --cluster=kubernetes-the-hard-way --user=admin"
    command = "kubectl config use-context kubernetes-the-hard-way"
    command = "echo 'done configuring the kubernetes remote user'"
  }
  
}


################################################################################
