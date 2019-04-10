#####################################################################                                                                                                     
# Bootstrapping the Kubernetes Worker Nodes
# In this lab you will bootstrap three Kubernetes worker nodes. The following components will be installed on each node: runc, container networking plugins, cri-containerd, 
# kubelet, and kube-proxy.                                                                                                                             
# Provision the Kubernetes worker nodes                                                                                                                                  
####################################################################                                                                                                      
                                                                                                                                                                          
# Create the Kubernetes configuration directory                                                                                                                           
# Download and Install the Kubernetes workers' binaries                                                                                                                 
                                                                                                                                                                          
resource "null_resource" "kube_workers_binaries" {                                                                                                                          
  count  = "${var.count}"                       
  depends_on = ["null_resource.cluster_role_binding","azurerm_lb_rule.lb","null_resource.kube_api_server_version_test"] 
  connection {                                                                                                                                                            
    type         = "ssh"                                                                                                                                                  
    host = "${element(var.worker_nodes_dns_names,count.index)}"                                                                                                             
    user         = "${var.worker_username}"                                                                                                                           
    password     = "${var.worker_password}"                                                                                                                           
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"                                                                                                                
    timeout      =  "1m"                                                                                                                                                  
    agent        = true                                                                                                                                                   
  }                                                                                                                                                                       
                                                                                                                                                                          
  provisioner "remote-exec" {                                                                                                                                             
    inline = [                                                                                                                                    
      "sudo apt-get update",   
      "sudo apt-get -y install socat conntrack ipset",                                                                                                                             
      "wget -q --show-progress --https-only --timestamping 'https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.13.0/crictl-v1.13.0-linux-amd64.tar.gz'",           
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17'",  
      "wget -q --show-progress --https-only --timestamping 'https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64'",           
      "wget -q --show-progress --https-only --timestamping 'https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz'",
      "wget -q --show-progress --https-only --timestamping 'https://github.com/containerd/containerd/releases/download/v1.2.0/containerd-1.2.0.linux-amd64.tar.gz'",
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubectl'",  
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-proxy'",
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubelet'", 
      "sudo mkdir -p /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes",
      "sudo mv runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 runsc",               
      "sudo mv runc.amd64 runc",
      "chmod +x kubectl kube-proxy kubelet runc runsc",
      "sudo mv kubectl kube-proxy kubelet runc runsc /usr/local/bin/",
      "sudo tar -xvf crictl-v1.13.0-linux-amd64.tar.gz -C /usr/local/bin/",
      "sudo tar -xvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/",
      "sudo tar -xvf containerd-1.2.0.linux-amd64.tar.gz -C /",
    ]                                                                                                                                                                     
  }                                                                                                                                                                       
}


resource "null_resource" "cni_networkk" {
  count = "${var.count}"
  depends_on = ["null_resource.kube_workers_binaries"]
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "file" {
    source      = "${path.module}/scripts/cni-network-kube-config.sh"
    destination = "/tmp/cni-network-kube-config.sh"
  }

  provisioner "file" {                              
    source      = "${path.module}/scripts/loopback-network-config.sh"      
    destination = "/tmp/loopback-network-config.sh" 
  }                                                   

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/cni-network-kube-config.sh",
      "sudo bash /tmp/cni-network-kube-config.sh",
      "sudo chmod +x /tmp/loopback-network-config.sh",
      "sudo bash /tmp/loopback-network-config.sh",
      "sudo mkdir -p /etc/containerd/",
    ]
  }
}



###########################################################################
#configure containerd
###############################

data "template_file" "containerd_toml_template" {
  template = "${file("${path.module}/configs/containerd.tpl")}"
  count = "${var.count}"
  depends_on = ["null_resource.cni_networkk"]
  #count = "${length(var.internal_master_private_ips)}"
}

resource "local_file" "containerd_toml_file" {
  count = "${var.count}"
   depends_on = ["data.template_file.containerd_toml_template"]
  content  = "${data.template_file.containerd_toml_template.*.rendered[count.index]}"
  filename = "./worker-configs/${element(var.worker_node_names, count.index)}-config.toml"
}

# Configure the containerd toml config file
resource "null_resource" "containerd_config" {
  #count = "${length(var.worker_node_names)}"
  count  = "${var.count}"
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  depends_on = ["local_file.containerd_toml_file"]

  provisioner "file" {
    source      = "./worker-configs/${element(var.worker_node_names, count.index)}-config.toml"
    destination = "~/config.toml"

  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv config.toml /etc/containerd/",
   ]
 }
}                   


########################################################
# containerd service
########################################################


data "template_file" "containerd_service_template" {
  template = "${file("${path.module}/configs/containerd-service.tpl")}"
  count = "${var.count}"
  depends_on = ["null_resource.containerd_config"]
  #count = "${length(var.internal_master_private_ips)}"
}

resource "local_file" "containerd_service_file" {
  count = "${var.count}"
  depends_on = ["data.template_file.containerd_service_template"]
  content  = "${data.template_file.containerd_service_template.*.rendered[count.index]}"
  filename = "./worker-configs/${element(var.worker_node_names, count.index)}-containerd.service"
}

# Configure the containerd service 
resource "null_resource" "containerd_service_config" {
  #count = "${length(var.worker_node_names)}"
  count  = "${var.count}"
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  depends_on = ["local_file.containerd_service_file"]

  provisioner "file" {
    source      = "./worker-configs/${element(var.worker_node_names, count.index)}-containerd.service"
    destination = "~/containerd.service"

  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv containerd.service /etc/systemd/system/",
   ]
 }
}
                                                      
#############################################################
# Kubelet
###############################################################      

resource "null_resource" "configure_kubelet_on_worker_node" {
  count = "${var.count}"
  depends_on = ["null_resource.containerd_service_config"]
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv ${element(var.worker_node_names, count.index)}-key.pem ${element(var.worker_node_names, count.index)}.pem /var/lib/kubelet/",
      "sudo mv ${element(var.worker_node_names, count.index)}.kubeconfig /var/lib/kubelet/kubeconfig",
      "sudo mv ca.pem /var/lib/kubernetes/",
    ]
  }
}
   
#################################
# kuebelet config file
################################                          
                                                                                           
data "template_file" "kubelet_configuration_template" {                                          
  template = "${file("${path.module}/configs/kubelet-config.tpl")}"                                    
  count = "${var.count}"       
  depends_on = ["null_resource.configure_kubelet_on_worker_node"]
  vars {
    count = "${var.count}"
    HOSTNAME = "${element(var.worker_node_names, count.index)}"
    POD_CIDR = "10.200.0.0/24"
    # "$(echo $(curl --silent -H Metadata:true "http://169.254.169.254/metadata/instance/compute/tags?api-version=2017-08-01&format=text") | cut -d : -f2)"
  }                                                                                                
}                                                                                          
                                                                                           
resource "local_file" "kubelet_configure_local_file" {                                             
  count = "${var.count}"       
  depends_on = ["data.template_file.kubelet_configuration_template"]                                                            
  content  = "${data.template_file.kubelet_configuration_template.*.rendered[count.index]}"      
  filename = "./worker-kubelet-configs/${element(var.worker_node_names, count.index)}-kubelet-config.yaml" 
}                                                                       


# store the kubelet config file across all the worker nodes
resource "null_resource" "kubelet_configg" {
  count  = "${var.count}"
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  depends_on = ["local_file.kubelet_configure_local_file"]

  provisioner "file" {
    source      = "./worker-kubelet-configs/${element(var.worker_node_names, count.index)}-kubelet-config.yaml"
    destination = "~/kubelet-config.yaml"

  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv kubelet-config.yaml /var/lib/kubelet/",
   ]
 }
}



########################################################                   
# kubelet service
###########################################################

data "template_file" "kubelet_service_template" {
  template = "${file("${path.module}/configs/kubelet-service.tpl")}"
  count = "${var.count}"
  depends_on = ["null_resource.kubelet_configg"]
}

resource "local_file" "kubelet_service_local_file" {
  count = "${var.count}"
  depends_on = ["data.template_file.kubelet_service_template"]
  content  = "${data.template_file.kubelet_service_template.*.rendered[count.index]}"
  filename = "./worker-kubelet-configs/${element(var.worker_node_names, count.index)}-kubelet.service"
}

# Configure the kubelet service
resource "null_resource" "kubelet_service_config" {
  count  = "${var.count}"
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  depends_on = ["local_file.kubelet_service_local_file"]

  provisioner "file" {
    source      = "./worker-kubelet-configs/${element(var.worker_node_names,count.index)}-kubelet.service"
    destination = "~/kubelet.service"

  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv kubelet.service /etc/systemd/system/",
    ]
  }
}

#####################################################################
# Configure the Kubernetes Proxy
#####################################################################

resource "null_resource" "configure_kubeproxy_on_worker_nodes" {               
  count = "${var.count}"                                                     
  depends_on = ["null_resource.kubelet_service_config"]                                                                             
  connection {                                                               
    type         = "ssh"                                                     
    host = "${element(var.worker_nodes_dns_names,count.index)}"                    
    user         = "${var.worker_username}"                                  
    password     = "${var.worker_password}"                                  
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"                   
    timeout      =  "1m"                                                     
    agent        = true                                                      
  }                                                                          
                                                                             
  provisioner "remote-exec" {                                                
    inline = [                                                               
      "sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig",                                
    ]                                                                        
  }                                                                          
}                                                                            
                                                                             
#################################                                            
# kube proxy config file                                                       
################################

data "template_file" "kubeproxy_config_template" {
  template = "${file("${path.module}/configs/kube-proxy-config.tpl")}"
  count = "${var.count}"
  depends_on = ["null_resource.configure_kubeproxy_on_worker_nodes"]
}

resource "local_file" "kubeproxy_config_local_file" {
  count = "${var.count}"
  depends_on = ["data.template_file.kubeproxy_config_template"]
  content  = "${data.template_file.kubeproxy_config_template.*.rendered[count.index]}"
  filename = "./worker-kube-proxy-configs/${element(var.worker_node_names, count.index)}-kube-proxy-config.yaml"
}


# store the kubelet config file across all the worker nodes
resource "null_resource" "kubeproxy_config" {
  count  = "${var.count}"
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  depends_on = ["local_file.kubeproxy_config_local_file"]

  provisioner "file" {
    source      = "./worker-kube-proxy-configs/${element(var.worker_node_names, count.index)}-kube-proxy-config.yaml"
    destination = "~/kube-proxy-config.yaml"

  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv kube-proxy-config.yaml /var/lib/kube-proxy/",
   ]
 }
} 

#################################################################
# Configure the kube-proxy service
#################################################################
data "template_file" "kubeproxy_service_template" {
  template = "${file("${path.module}/configs/kube-proxy-service.tpl")}"
  count = "${var.count}"
  depends_on = ["null_resource.kubeproxy_config"]
}

resource "local_file" "kubeproxy_service_local_file" {
  count = "${var.count}"
  depends_on = ["data.template_file.kubeproxy_service_template"]
  content  = "${data.template_file.kubeproxy_service_template.*.rendered[count.index]}"
  filename = "./worker-kube-proxy-configs/${element(var.worker_node_names, count.index)}-kube-proxy.service"
}

# Configure the kube-proxy service
resource "null_resource" "kubeproxy_service_config" {
  count  = "${var.count}"
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  depends_on = ["local_file.kubeproxy_service_local_file"]

  provisioner "file" {
    source      = "./worker-kube-proxy-configs/${element(var.worker_node_names,count.index)}-kube-proxy.service"
    destination = "~/kube-proxy.service"

  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv kube-proxy.service /etc/systemd/system/",
    ]
  }
}
##################################################################################
# Start the Worker Services
##################################################################################

resource "null_resource" "start_worker_services" {
  count  = "${var.count}"
  depends_on = ["null_resource.kubeproxy_service_config"]
  connection {
    type         = "ssh"
    host = "${element(var.worker_nodes_dns_names,count.index)}"
    user         = "${var.worker_username}"
    password     = "${var.worker_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable containerd kubelet kube-proxy",
      "sudo systemctl start containerd kubelet kube-proxy",
    ]
  }
}

################################################################################                


   
