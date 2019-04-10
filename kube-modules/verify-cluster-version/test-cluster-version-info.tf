                                                             
# Verify the Kubernetes API Server by an HTTP request                        

/*
resource "local_file" "kube_public_ip_file" {
  content  = "${var.kube_public_ip}"
  filename = "./kube-verify-api-server/KUBERNETES_PUBLIC_IP_ADDRESS"
}*/

resource "null_resource" "kube_api_server_version_test" {  
  depends_on = ["null_resource.cluster_role_binding"]
  #KUBERNETES_PUBLIC_IP_ADDRESS = "${var.kube_public_ip}"                      
  /*                                                          
  connection {                                               
    type         = "ssh"                                     
    host = "${element(var.controller_dns_names,0)}"
    user         = "${var.api_server_username}"              
    password     = "${var.api_server_password}"              
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"   
    timeout      =  "1m"                                     
    agent        = true                                      
  }
     
  depends_on = ["null_resource.cluster_role_binding","local_file.kube_public_ip_file"]
  provisioner "file" {
    source   = "./kube-verify-api-server/KUBERNETES_PUBLIC_IP_ADDRESS"
    destination =  "~/KUBERNETES_PUBLIC_IP"

  }
  provisioner "file" {
    source      = "apiserver-test.sh"
    destination = "/tmp/apiserver-test.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/apiserver-test.sh",
      "bash /tmp/apiserver-test.sh ${KUBERNETES_PUBLIC_IP}",
    ]
  }                                                       
   */                                                          
  provisioner "local-exec" {                                
    command = "echo 'verify the cluster version info'"
    command = "echo 'Start checking the api server health .....................'"                
    command = "curl --cacert tls-certs/client-server/ca.pem https://$KUBERNETES_PUBLIC_IP_ADDRESS:6443/version"
    command = "echo 'Okk!!! finished testing the api server health check'" 
    command =  "echo done"
                                           
    environment = {
      KUBERNETES_PUBLIC_IP_ADDRESS = "${var.kubernetes_public_ip_address}"
    }
                   
  }
                                                            
}                                                            
                                                             
