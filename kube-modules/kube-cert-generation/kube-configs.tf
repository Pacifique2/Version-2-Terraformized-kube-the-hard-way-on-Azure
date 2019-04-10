

# Generating kubernetes Config Files for Authentication
  ## Generate kubelet configuration file
resource "null_resource" "gen_kube_kubelet_config" {
  count = "${var.count}"
  depends_on = ["null_resource.distribute_kubelet_certs_keys"]
  provisioner "local-exec" {
      command =<<EOT
          kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=certs/generated/ca.pem --embed-certs=true --server=https://${var.public_kubernetes_ip}:6443 --kubeconfig=certs/generated/${element(var.worker_node_names, count.index)}.kubeconfig
          kubectl config set-credentials system:node:${element(var.worker_node_names, count.index)} --client-certificate=certs/generated/${element(var.worker_node_names, count.index)}.pem --client-key=certs/generated/${element(var.worker_node_names, count.index)}-key.pem --embed-certs=true --kubeconfig=certs/generated/${element(var.worker_node_names, count.index)}.kubeconfig
          kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:node:${element(var.worker_node_names, count.index)} --kubeconfig=certs/generated/${element(var.worker_node_names, count.index)}.kubeconfig
          kubectl config use-context default --kubeconfig=certs/generated/${element(var.worker_node_names, count.index)}.kubeconfig
      EOT
  }
}

 ## Generate kube-proxy configuration file
resource "null_resource" "gen_kube_kubeproxy_config" {
  depends_on = ["null_resource.gen_kube_kubelet_config"]
  provisioner "local-exec" {
    command =<<EOT
      kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=certs/generated/ca.pem --embed-certs=true --server=https://${var.public_kubernetes_ip}:6443 --kubeconfig=certs/generated/kube-proxy.kubeconfig                                   
      kubectl config set-credentials system:kube-proxy --client-certificate=certs/generated/kube-proxy.pem --client-key=certs/generated/kube-proxy-key.pem --embed-certs=true --kubeconfig=certs/generated/kube-proxy.kubeconfig
      kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-proxy --kubeconfig=certs/generated/kube-proxy.kubeconfig
      kubectl config use-context default --kubeconfig=certs/generated/kube-proxy.kubeconfig
    EOT
  }   
}

## Generate kube-controller-manager configuration file
resource "null_resource" "gen_kube_kubecontrollermanager_config" {
  depends_on = ["null_resource.gen_kube_kubeproxy_config"]
  provisioner "local-exec" {
    command =<<EOT
        kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=certs/generated/ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=certs/generated/kube-controller-manager.kubeconfig             
        kubectl config set-credentials system:kube-controller-manager --client-certificate=certs/generated/kube-controller-manager.pem --client-key=certs/generated/kube-controller-manager-key.pem --embed-certs=true --kubeconfig=certs/generated/kube-controller-manager.kubeconfig
        kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-controller-manager --kubeconfig=certs/generated/kube-controller-manager.kubeconfig
        kubectl config use-context default --kubeconfig=certs/generated/kube-controller-manager.kubeconfig
    EOT
  }   
}

## Generate kube-scheduler configuration file
resource "null_resource" "gen_kube_kubescheduler_config" {
  depends_on = ["null_resource.gen_kube_kubecontrollermanager_config"]
  provisioner "local-exec" {
    command =<<EOT
      kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=certs/generated/ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=certs/generated/kube-scheduler.kubeconfig    
      kubectl config set-credentials system:kube-scheduler --client-certificate=certs/generated/kube-scheduler.pem --client-key=certs/generated/kube-scheduler-key.pem --embed-certs=true --kubeconfig=certs/generated/kube-scheduler.kubeconfig
      kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-scheduler --kubeconfig=certs/generated/kube-scheduler.kubeconfig
      kubectl config use-context default --kubeconfig=certs/generated/kube-scheduler.kubeconfig
  EOT
  }   
}

 ## Generate admin configuration file
resource "null_resource" "gen_kube_admin_config" {
  depends_on = ["null_resource.gen_kube_kubescheduler_config"]
  provisioner "local-exec" {
    command =<<EOT
      kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=certs/generated/ca.pem --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=certs/generated/admin.kubeconfig
      kubectl config set-credentials admin --client-certificate=certs/generated/admin.pem --client-key=certs/generated/admin-key.pem --embed-certs=true --kubeconfig=certs/generated/admin.kubeconfig
      kubectl config set-context default --cluster=kubernetes-the-hard-way --user=admin --kubeconfig=certs/generated/admin.kubeconfig
      kubectl config use-context default --kubeconfig=certs/generated/admin.kubeconfig
    EOT
  }   
}

# Distribute the Configuration Files to each Worker instances

# Distribute the Configuration Files to each Controller instance


# Generating  Data Encryption Config and Key
resource "null_resource" "gen_data_encryption_config_key" {
  depends_on = ["null_resource.gen_kube_admin_config"]
  count = "${var.count}"
  provisioner "local-exec" {
    command = <<EOT
       ENCRYPTION_KEY=$$(head -c 32 /dev/urandom | base64)
       cat > certs/configs/encryption-config.yaml <<EOF
       kind: EncryptionConfig
       apiVersion: v1
       resources:
        - resources:
        - secrets
       providers:
        - aescbc:
            keys:
              - name: key1
                secret: $${ENCRYPTION_KEY}
        - identity: {}
    EOT
   # command = "gcloud compute scp encryption-config.yaml controller-${count.index}:~/"
  }
}


resource "null_resource" "distribute_configs_to_workers" {
  count = "${length(var.kube_worker_node_names)}"

  depends_on = ["null_resource.gen_data_encryption_config_key"]

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
    source      = "./certs/generated/${element(var.kube_worker_node_names, count.index)}.kubeconfig"
    destination = "~/${element(var.kube_worker_node_names, count.index)}.kubeconfig"
  }
  provisioner "file" {
    source      = "./certs/generated/kube-proxy.kubeconfig"
    destination = "~/kube-proxy.kubeconfig"
  }
  
}

######################################################
#

resource "null_resource" "distribute_the_control_plane_configs" {            
  count = "${var.nodes_count}"                                              
                                                                            
  depends_on = ["null_resource.distribute_configs_to_workers"]                
                                                                            
  connection {                                                              
    type         = "ssh"                                                    
    host = "${element(var.master_nodes_dns_names,count.index)}"             
    user         = "${var.api_server_username}"                             
    password     = "${var.api_server_password}"                             
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"                  
    timeout      =  "1m"                                                    
    agent        = true                                                     
  }                                                                         
                                                                            
  provisioner "file" {                                                      
    source      = "./certs/generated/kube-controller-manager.kubeconfig"
    destination = "~/kube-controller-manager.kubeconfig"                    
  }           
  provisioner "file" {                                               
    source      = "./certs/generated/kube-scheduler.kubeconfig"  
    destination = "~/kube-scheduler.kubeconfig"                      
  }
  provisioner "file" {                                               
    source      = "./certs/generated/admin.kubeconfig"  
    destination = "~/admin.kubeconfig"                      
  }                                   
  provisioner "file" {                                               
    source      = "./certs/configs/encryption-config.yaml" 
    destination = "~/encryption-config.yaml"                         
  }                                                                                                                                                                                   
}                                                                           




























/*
data "template_file" "kubelet_config_template" {
  template =<<EOT
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: $${certificate-authority-data}
        server: https://$${public_kubernetes_ip}:6443
      name: kubernetes-the-hard-way
    contexts:
    - context:
        cluster: kubernetes-the-hard-way
        user: system:node:$${worker_node}
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: system:node:$${worker_node}
      user:
        as-user-extra: {}
        client-certificate-data: $${client-certificate-data}
        client-key-data: $${client-key-data}
  EOT
  depends_on = [
          "null_resource.devo_ca_certs","null_resource.kubelet_certs","null_resource.worker_ca_cert","null_resource.kubernetes_certs",
           "null_resource.service-account_certs",
  ]
  count = "${var.nodes_count}"

  vars {
    certificate-authority-data = "${base64encode(tls_self_signed_cert.devo_kube_ca.cert_pem)}"
    # "${base64encode(var.kube_ca_crt_pem)}"
    client-key-data            = "${base64encode(tls_private_key.kubelet_worker_prkey.*.private_key_pem[count.index])}"
    # "element(var.kubelet_crt_pems, count.index)"
    client-certificate-data    = "${base64encode(tls_locally_signed_cert.kubelet_worker_ca.*.cert_pem[count.index])}"
    #"${base64encode(element(var.kubelet_key_pems, count.index))}"
    public_kubernetes_ip        = "${var.public_kubernetes_ip}"
    worker_node                = "${element(var.kube_worker_node_names, count.index)}"
  }
}

resource "local_file" "kubelet_config" {
  count    = "${length(var.kube_worker_node_names)}"
  depends_on = ["data.template_file.kubelet_config_template"]
  content  = "${data.template_file.kubelet_config_template.*.rendered[count.index]}"
  filename = "./configs/${element(var.kube_worker_node_names, count.index)}.kubeconfig"
}

resource "null_resource" "kubelet_provisioner" {
  count = "${length(var.kube_worker_node_names)}"

  depends_on = ["local_file.kubelet_config"]
  
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
    source      = "./configs/${element(var.kube_worker_node_names, count.index)}.kubeconfig"
    destination = "~/${element(var.kube_worker_node_names, count.index)}.kubeconfig"
  }
}

########################################################################
# Kube-proxy config file
########################################################################

data "template_file" "kube-proxy_config_template" {
  template =<<EOT
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: $${certificate-authority-data}
        server: https://$${public_kubernetes_ip}:6443
      name: kubernetes-the-hard-way
    contexts:
    - context:
        cluster: kubernetes-the-hard-way
        user: kube-proxy
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: kube-proxy
      user:
        as-user-extra: {}
        client-certificate-data: $${client-certificate-data}
        client-key-data: $${client-key-data}
  EOT
  depends_on = [
          "null_resource.devo_ca_certs","null_resource.kubelet_certs","null_resource.worker_ca_cert","null_resource.kubernetes_certs",
           "null_resource.service-account_certs",
  ]
  vars {
    certificate-authority-data = "${base64encode(tls_self_signed_cert.devo_kube_ca.cert_pem)}"
    client-certificate-data    = "${base64encode(tls_locally_signed_cert.kube_proxy.cert_pem)}"
    client-key-data            = "${base64encode(tls_private_key.kube_proxy.private_key_pem)}"
    public_kubernetes_ip       = "${var.public_kubernetes_ip}"
  }
}

resource "local_file" "kube-proxy_config" {
  depends_on = ["data.template_file.kube-proxy_config_template"]
  content  = "${data.template_file.kube-proxy_config_template.rendered}"
  filename = "./configs/kube-proxy.kubeconfig"
}

resource "null_resource" "kube-proxy-provisioner" {
  count = "${length(var.kube_worker_node_names)}"

  depends_on = ["local_file.kube-proxy_config"]
  
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
    source      = "./configs/kube-proxy.kubeconfig"
    destination = "~/kube-proxy.kubeconfig"
  }
}

############################################################################
# kube-controller-manger to distribute to controller nodes
# Generate a kubeconfig file for the kube-controller-manager service:
############################################################################

data "template_file" "kube-controller-manager_config_template" {
  template =<<EOT
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: $${certificate-authority-data}
        server: https://127.0.0.1:6443
      name: kubernetes-the-hard-way
    contexts:
    - context:
        cluster: kubernetes-the-hard-way
        user: system:kube-controller-manager
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: system:kube-controller-manager
      user:
        as-user-extra: {}
        client-certificate-data: $${client-certificate-data}
        client-key-data: $${client-key-data}
  EOT
  depends_on = [
          "null_resource.devo_ca_certs","null_resource.kubelet_certs","null_resource.worker_ca_cert","null_resource.kubernetes_certs",
           "null_resource.service-account_certs",
  ]
  vars {
    certificate-authority-data = "${base64encode(tls_self_signed_cert.devo_kube_ca.cert_pem)}"
    client-certificate-data    = "${base64encode(tls_locally_signed_cert.kube_controller_manager.cert_pem)}"
    client-key-data            = "${base64encode(tls_private_key.kube_controller_manager.private_key_pem)}"
  }
}

resource "local_file" "kube-controller-manager_config" {
  depends_on = ["data.template_file.kube-controller-manager_config_template"]
  content  = "${data.template_file.kube-controller-manager_config_template.rendered}"
  filename = "./configs-controllers/kube-controller-manager.kubeconfig"
}

resource "null_resource" "kube-controller-manager-provisioner" {
  count = "${var.nodes_count}"

  depends_on = ["local_file.kube-controller-manager_config"]

  connection {
    type         = "ssh"
    host = "${element(var.master_nodes_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "file" {
    source      = "./configs-controllers/kube-controller-manager.kubeconfig"
    destination = "~/kube-controller-manager.kubeconfig"
  }
}

#################################################################################
# Kube-schedular
# Generate a kubeconfig file for the kube-scheduler service
#################################################################################

data "template_file" "kube-scheduler_config_template" {
  template =<<EOT
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: $${certificate-authority-data}
        server: https://127.0.0.1:6443
      name: kubernetes-the-hard-way
    contexts:
    - context:
        cluster: kubernetes-the-hard-way
        user: system:kube-scheduler
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: system:kube-scheduler
      user:
        as-user-extra: {}
        client-certificate-data: $${client-certificate-data}
        client-key-data: $${client-key-data}
  EOT
  depends_on = [
          "null_resource.devo_ca_certs","null_resource.kubelet_certs","null_resource.worker_ca_cert","null_resource.kubernetes_certs",
           "null_resource.service-account_certs",
  ]
  vars {
    certificate-authority-data = "${base64encode(tls_self_signed_cert.devo_kube_ca.cert_pem)}"
    client-certificate-data    = "${base64encode(tls_locally_signed_cert.kube_scheduler.cert_pem)}"
    client-key-data            = "${base64encode(tls_private_key.kube_scheduler.private_key_pem)}"
  }
}

resource "local_file" "kube-scheduler-config" {
  depends_on = ["data.template_file.kube-scheduler_config_template"]
  content  = "${data.template_file.kube-scheduler_config_template.rendered}"
  filename = "./configs-controllers/kube-scheduler.kubeconfig"
}

resource "null_resource" "kube-scheduler-provisioner" {
  count = "${var.nodes_count}"

  depends_on = ["local_file.kube-scheduler-config"]

  connection {
    type         = "ssh"
    host = "${element(var.master_nodes_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "file" {
    source      = "./configs-controllers/kube-scheduler.kubeconfig"
    destination = "~/kube-scheduler.kubeconfig"
  }
}

#################################################################################
# The admin Kubernetes Configuration File
# Generate a kubeconfig file for the admin user:
#################################################################################
data "template_file" "admin_config_template" {
  template =<<EOT
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: $${certificate-authority-data}
        server: https://127.0.0.1:6443
      name: kubernetes-the-hard-way
    contexts:
    - context:
        cluster: kubernetes-the-hard-way
        user: admin
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: admin
      user:
        as-user-extra: {}
        client-certificate-data: $${client-certificate-data}
        client-key-data: $${client-key-data}
  EOT
  depends_on = [
          "null_resource.devo_ca_certs","null_resource.kubelet_certs","null_resource.worker_ca_cert","null_resource.kubernetes_certs",
           "null_resource.service-account_certs",
  ]
  vars {
    certificate-authority-data = "${base64encode(tls_self_signed_cert.devo_kube_ca.cert_pem)}"
    client-certificate-data    = "${base64encode(tls_locally_signed_cert.devo_kube_admin.cert_pem)}"
    client-key-data            = "${base64encode(tls_private_key.devo_kube_admin.private_key_pem)}"
  }
}

resource "local_file" "admin_config" {
  depends_on = ["data.template_file.admin_config_template"]
  content  = "${data.template_file.admin_config_template.rendered}"
  filename = "./configs-adminUser/admin.kubeconfig"
}

resource "null_resource" "admin-provisioner" {
  count = "${var.nodes_count}"

  depends_on = ["local_file.admin_config"]

  connection {
    type         = "ssh"
    host = "${element(var.master_nodes_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "file" {
    source      = "./configs-adminUser/admin.kubeconfig"
    destination = "~/admin.kubeconfig"
  }
}

#################################################################
#
#################################################################

resource "random_string" "kube_data_encryption_key" {
  length = 32
}

data "template_file" "encryption_config_template" {
  template =<<EOT
    kind: EncryptionConfig
    apiVersion: v1
    resources:
      - resources:
          - secrets
        providers:
          - aescbc:
              keys:
                - name: key1
                  secret: $${kube_data_encryption_key}
          - identity: {}
  EOT
  depends_on = [
          "null_resource.devo_ca_certs","null_resource.kubelet_certs","null_resource.worker_ca_cert","null_resource.kubernetes_certs",
           "null_resource.service-account_certs","random_string.kube_data_encryption_key",
  ]
  vars {
    kube_data_encryption_key = "${base64encode(random_string.kube_data_encryption_key.result)}"
  }
}

resource "local_file" "data_encryption_config" {
  depends_on = ["data.template_file.encryption_config_template"]
  content  = "${data.template_file.encryption_config_template.rendered}"
  filename = "./configs-data-encryption/encryption-config.yaml"
}

resource "null_resource" "encryption_config-provisioner" {
  count = "${var.nodes_count}"
  depends_on = ["local_file.data_encryption_config"]
  connection {
    type         = "ssh"
    host = "${element(var.master_nodes_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "file" {
    source      = "./configs-data-encryption/encryption-config.yaml"
    destination = "~/encryption-config.yaml"
  }
}

#######################################################################
# ENd of data encryption config file
#######################################################################

*/
