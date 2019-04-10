#####################################################################
# Bootstrapping the Kubernetes Control Plane
# Provision the Kubernetes Control Plane
####################################################################

# Create the Kubernetes configuration directory 
# Download and Install the Kubernetes Controller Binaries

resource "null_resource" "kube_control_binaries" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on = ["null_resource.etcd_server_test"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.kube_controlller_binaries}",
      "sudo mkdir -p /etc/kubernetes/config",
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-apiserver'", 
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-controller-manager'",
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-scheduler'",
      "wget -q --show-progress --https-only --timestamping 'https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubectl'",
      "chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl",
      "sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/",
    ]
  }
}


# Configure the Kubernetes API Server
resource "null_resource" "kube_api_server_config" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on = ["null_resource.kube_control_binaries"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/lib/kubernetes/",
      "sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem encryption-config.yaml /var/lib/kubernetes/",
    ]
  }
}

# Create the kube-apiserver.service systemd unit file

data "template_file" "kube_api_server_service_template" {
  template =<<EOT
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=$${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=$${COUNT} \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
  EOT
  count = "${var.count}"
  depends_on = ["null_resource.kube_api_server_config"]
  # count = "${length(var.internal_master_private_ips)}"
  vars {
    INTERNAL_IP = "${element(var.internal_master_private_ips, count.index)}"
    COUNT = "${var.count}" 
    #COUNT       =  "${length(var.controller_node_names)}"
    /*m1 = "controller-terraform-0"
    m2 = "controller-terraform-1"
    m3 = "controller-terraform-2"
    */
  }
}

resource "local_file" "api_server_service_config" {
  # count    = "${length(var.internal_master_private_ips)}"
  count  = "${var.count}"
  depends_on = ["data.template_file.kube_api_server_service_template"]
  content  = "${data.template_file.kube_api_server_service_template.*.rendered[count.index]}"
  filename = "./configs-api-server-service/${element(var.controller_node_names, count.index)}.kube-apiserver.service"
}

# Configure the api-server 
resource "null_resource" "kube_apiserver" {
  count = "${length(var.controller_node_names)}"
  depends_on = ["local_file.api_server_service_config"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  # depends_on = ["local_file.api_server_service_config"]

  provisioner "file" {
    source      = "./configs-api-server-service/${element(var.controller_node_names, count.index)}.kube-apiserver.service"
    destination = "~/kube-apiserver.service"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo mv kube-apiserver.service /etc/systemd/system/",
      
    ]
  }
  
}

#############################################################
# Configure the Kubernetes Controller Manager 
#############################################################

# Move the kube-controller-manager kubeconfig into place:

resource "null_resource" "move_kube_contoller_manager_config" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on = ["null_resource.kube_apiserver"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/",
    ]
  }
}

# Create the kube-controller-manager.service systemd unit file:

data "template_file" "kube_controller_manager_service_template" {
  template =<<EOT
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
  EOT
  count = "${var.count}"
  depends_on = ["null_resource.move_kube_contoller_manager_config"]
  /*vars {
    INTERNAL_IP = "${element(var.internal_master_private_ips, count.index)}"
    COUNT       =  "${length(var.controller_node_names)}"
    m1 = "controller-terraform-0"
    m2 = "controller-terraform-1"
    m3 = "controller-terraform-2"
  }
  */
}

resource "local_file" "kube_controller_manager_service_config" {
  count  = "${var.count}"
  depends_on = ["data.template_file.kube_controller_manager_service_template"]
  content  = "${data.template_file.kube_controller_manager_service_template.*.rendered[count.index]}"
  filename = "./configs-controller-manager-service/kube-controller-manager.service"
}

# Configure the kube-controller-manager                                                          
resource "null_resource" "kube_api_server" {                                                                                
  #count = "${length(var.controller_node_names)}"
  count  = "${var.count}"                                                                            
  depends_on = ["local_file.kube_controller_manager_service_config"]                                                                                                                          
  connection {                                                                                                              
    type         = "ssh"                                                                                                    
    host = "${element(var.controller_dns_names,count.index)}"                                                               
    user         = "${var.api_server_username}"                                                                             
    password     = "${var.api_server_password}"                                                                             
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"                                                                  
    timeout      =  "1m"                                                                                                    
    agent        = true                                                                                                     
  }                                                                                                                         
                                                                                                                            
  # depends_on = ["local_file.kube_controller_manager_service_config"]                                                                     
                                                                                                                            
  provisioner "file" {                                                                                                      
    source      = "./configs-controller-manager-service/kube-controller-manager.service"  
    destination = "~/kube-controller-manager.service"                                                              
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv kube-controller-manager.service /etc/systemd/system/",
      ]
  }                                    
}
####################################################################################
# Configure the Kubernetes Scheduler
# and move the kube-scheduler kubeconfig into place:
###################################################################################

# Move the kube-scheduler kubeconfig into place:

resource "null_resource" "move_kube_scheduler_config" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on = ["null_resource.kube_api_server"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/",
    ]
  }
}

data "template_file" "kube_scheduler_yaml_template" {
  template =<<EOT
    apiVersion: kubescheduler.config.k8s.io/v1alpha1
    kind: KubeSchedulerConfiguration
    clientConnection:
      kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
   leaderElection:
     leaderElect: true
  EOT
  count = "${var.count}"
  depends_on = ["null_resource.move_kube_scheduler_config"]
  #count = "${length(var.internal_master_private_ips)}"
}

resource "local_file" "kube_scheduler_yaml_config" {
  count = "${var.count}"
  depends_on = ["data.template_file.kube_scheduler_yaml_template"]
  content  = "${data.template_file.kube_scheduler_yaml_template.*.rendered[count.index]}"
  filename = "./configs-kube-scheduler/${element(var.controller_node_names, count.index)}-kube-scheduler.yaml"
}

# Configure the kube-scheduler yaml config file
resource "null_resource" "kube_scheduler_config" {
  #count = "${length(var.controller_node_names)}"
  count  = "${var.count}"
  depends_on = ["local_file.kube_scheduler_yaml_config"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  #depends_on = ["local_file.kube_scheduler_yaml_config"]

  provisioner "file" {
    source      = "./configs-kube-scheduler/${element(var.controller_node_names, count.index)}-kube-scheduler.yaml"
    destination = "~/kube-scheduler.yaml"
  }
  provisioner "remote-exec" {                                   
   inline = [  
     "sudo mkdir -p /etc/kubernetes/config/",                                                
     "sudo mv kube-scheduler.yaml /etc/kubernetes/config/", 
   ]                                                           
  }                                                             
}                                      

####################################################################
# Create the kube-scheduler.service systemd unit file:


data "template_file" "kube_scheduler_service_template" {
  template =<<EOT
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
  EOT
  count = "${var.count}"
  depends_on = ["null_resource.kube_scheduler_config"]
}

resource "local_file" "kube_scheduler_service" {
  count = "${var.count}"
  depends_on = ["data.template_file.kube_scheduler_service_template"]
  content  = "${data.template_file.kube_scheduler_service_template.*.rendered[count.index]}"
  filename = "./configs-kube-scheduler/${element(var.controller_node_names, count.index)}-kube-scheduler.service"
}


# Configure the kube-scheduler system unit file                      
resource "null_resource" "kube_scheduler_service" {                   
  #count = "${length(var.controller_node_names)}"                     
  count  = "${var.count}"
  depends_on = ["local_file.kube_scheduler_service"]                                                                   
  connection {                                                       
    type         = "ssh"                                             
    host = "${element(var.controller_dns_names,count.index)}"        
    user         = "${var.api_server_username}"                      
    password     = "${var.api_server_password}"                      
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"           
    timeout      =  "1m"                                             
    agent        = true                                              
  }                                                                  
                                                                     
  # depends_on = ["local_file.kube_scheduler_service"]             
                                                                     
  provisioner "file" {                                               
    source      = "./configs-kube-scheduler/${element(var.controller_node_names, count.index)}-kube-scheduler.service"     
    destination = "~/kube-scheduler.service"                            
  }                                                                  
  provisioner "remote-exec" {                                       
   inline = [                                                        
     "sudo mv kube-scheduler.service /etc/systemd/system/",          
   ]                                                                 
  }                                                                   
} 

##########################################
# Start the Controller Services           
                                                        
resource "null_resource" "start_controller_services" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on = ["null_resource.kube_scheduler_service"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler",
      "sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler",
    ]
  }
}

###################################################################################
/* Enable HTTP Health Checks
A Google Network Load Balancer will be used to distribute traffic across the three API servers and allow each API server to terminate TLS connections and validate client certificates. The network load balancer only supports HTTP health checks which means the HTTPS endpoint exposed by the API server cannot be used. As a workaround the nginx webserver can be used to proxy HTTP health checks. In this section nginx will be installed and configured to accept HTTP health checks on port 80 and proxy the connections to the API server on https://127.0.0.1:6443/healthz.

The /healthz API server endpoint does not require authentication by default.
*/
########################################################################################

resource "null_resource" "nginx_install" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on = ["null_resource.start_controller_services"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }
  # depends_on = ["null_resource.start_controller_services"]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y nginx",
      "sudo mkdir scripts",
    ]
  }
}

data "template_file" "kube_default_service_local_template" {
  template =<<EOT
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
  EOT
  count = "${var.count}"
  depends_on = ["null_resource.nginx_install"]
}

resource "local_file" "kube_default_service_local_file" {
  count = "${var.count}"
  depends_on = ["data.template_file.kube_default_service_local_template"]
  content  = "${data.template_file.kube_default_service_local_template.*.rendered[count.index]}"
  filename = "./kube-health-check/${element(var.controller_node_names, count.index)}-kubernetes.default.svc.cluster.local"
}


# Configure the helth check service and test it
resource "null_resource" "kube_health__check_service" {
  #count = "${length(var.controller_node_names)}"
  count  = "${var.count}"
  depends_on = ["local_file.kube_default_service_local_file"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }
  # depends_on = ["local_file.kube_default_service_local_file"]

  provisioner "file" {
    source      = "./kube-health-check/${element(var.controller_node_names, count.index)}-kubernetes.default.svc.cluster.local"
    destination = "~/kubernetes.default.svc.cluster.local"
  }
  provisioner "remote-exec" {
   inline = [
     "sudo mv kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local",
     "sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/",
     "sudo systemctl restart nginx",
     "sudo systemctl enable nginx",
     "kubectl get componentstatuses --kubeconfig admin.kubeconfig",
     "curl -H 'Host: kubernetes.default.svc.cluster.local' -i http://127.0.0.1/healthz",
   ]
  }
}
################################################################

# RBAC for Kubelet Authorization
#
# In this section we shall configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. 
# Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

# This terraform section sets the Kubelet --authorization-mode flag to Webhook.
# Webhook mode uses the SubjectAccessReview API to determine authorization.

################################################################
# Create the system:kube-apiserver-to-kubelet ClusterRole with permissions to access
# the Kubelet API and perform most common tasks associated with managing pods:

resource "null_resource" "cluster_role" {
  # count = "${length(var.controller_node_names)}"
  depends_on = ["null_resource.kube_health__check_service"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,0)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }
  /*
  provisioner "file" {
    source      = "./scripts/clusterRole-script.sh"
    #source       = "${file("${path.module}/scripts/clusterRole-script.sh")}"
    destination = "~/clusterRole-script.sh"
  }
  */
  provisioner "remote-exec" {
    /*inline = [
      "sudo mv clusterRole-script.sh scripts/",
      "sudo chmod +x scripts/clusterRole-script.sh",
      "sudo bash scripts/clusterRole-script.sh",
    ]*/
    script = "${path.module}/scripts/clusterRole-script.sh"
  }
}

#############################################################################################
# The Kubernetes API Server authenticates to the Kubelet as the kubernetes user using the client certificate 
# as defined by the --kubelet-client-certificate flag.

# Bind the system:kube-apiserver-to-kubelet ClusterRole to the kubernetes user:

resource "null_resource" "cluster_role_binding" {
  #count = "${length(var.controller_node_names)}"
  depends_on = ["null_resource.cluster_role"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,0)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }
  /*
  provisioner "file" {
    # source       = "${file("${path.module}/scripts/clusterRoleBinding-script.sh")}"
    source      = "./scripts/clusterRoleBinding-script.sh"
    destination = "~/clusterRoleBinding-script.sh"
  }
  */
  provisioner "remote-exec" {
    /*inline = [
      "echo 'restarting the cluster role binding rule' ",
      "sudo mv clusterRoleBinding-script.sh scripts/",
      "sudo chmod +x scripts/clusterRoleBinding-script.sh",
      "sudo bash scripts/clusterRoleBinding-script.sh",
    ]
    */
    script = "${path.module}/scripts/clusterRoleBinding-script.sh"
  }
}
                             
