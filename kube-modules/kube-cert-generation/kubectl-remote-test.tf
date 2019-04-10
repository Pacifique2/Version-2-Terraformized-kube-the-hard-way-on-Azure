

#Verification 
#Check the health of the remote Kubernetes cluster:


resource "null_resource" "kubectl_testing" {
  depends_on  = ["null_resource.start_worker_services","null_resource.kubectl_remote_setup"]
  
 provisioner "local-exec" {
   command = "echo 'testing the remote user with kubectl'"
   command = "kubectl get componentstatuses"
   # List the nodes in the remote Kubernetes cluster:

   command = "kubectl get nodes"

   command = "echo 'done testing with kubectl'"
 }
}
