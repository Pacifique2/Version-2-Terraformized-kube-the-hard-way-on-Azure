provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.23.0"

  subscription_id = "${var.subscription_id}"
  
}

module "kube_vnet" {
  source = "./kube-modules/kube-vnet"
  pods_route_table_id = "${module.pods_route_table.route_table_id}"
}

module "pods_route_table" {                     
  source = "./kube-modules/kube-pods-route-table"
  routes_count = "${var.number_of_nodes}"
  rsg_name = "${module.kube_vnet.rsg_name}"
  rs_location = "${module.kube_vnet.rsg_location}"
  subnet_id   = "${module.kube_vnet.subnet_id}"
  disable_bgp_route_propagation = "${var.deny_bgp_route_propagation}"
}                                        

module "lb" {
  source = "./kube-modules/kube-pip-lb"
   rs_name = "${module.kube_vnet.rsg_name}"
   rs_location = "${module.kube_vnet.rsg_location}"
   frontend_ip_configuration_name = "${var.lb_frontend_ip_conf_name}"
}

module "master-nodes" {
  source = "./kube-modules/kube-nodes"
  rs_name = "${module.kube_vnet.rsg_name}"
  rs_location = "${module.kube_vnet.rsg_location}"
  node   = "controller"
  kube_subnet_id  = "${module.kube_vnet.subnet_id}"
  root_ip = "10.240.0.1"
  node_prefix = "controller-terraform"
  username = "${var.controller_username}"
  password = "${var.controller_password}"
  lb_backend_pool = "${module.lb.lb_backend_pool}"
  controller_count = "${var.number_of_nodes}"
  #ssh_key_data  = "${var.ssh_public_key}"
}

module "worker-nodes" {                                 
  source = "./kube-modules/kube-worker-nodes"
  rs_name = "${module.kube_vnet.rsg_name}"   
  rs_location = "${module.kube_vnet.rsg_location}"
  node   = "worker"                       
  kube_subnet_id  = "${module.kube_vnet.subnet_id}"
  root_ip = "10.240.0.2"                           
  node_prefix = "worker-terraform"                       
  username = "${var.w_username}"                            
  password = "${var.w_password}"
  worker_count = "${var.number_of_nodes}"
  #ssh_key_data  = "${var.ssh_public_key}"                        
  #lb_backend_pool = "${module.lb.lb_backend_pool}"    
}
/*
resource "null_resource" "local_controllers_testing" {

    depends_on = ["module.master-nodes"]

    # This replicates the provisioning steps performed by Vagrant
    provisioner "local-exec" {
        command = "echo 'testing master nodes dependecies'"
    }
}

resource "null_resource" "local_workers_testing" {

    depends_on = ["module.worker-nodes"]

    # This replicates the provisioning steps performed by Vagrant
    provisioner "local-exec" {
        command = "echo 'testing kube worker nodes dependencies'"
    }
} 
*/

module "certs" {
  source = "./kube-modules/kube-cert-generation"

  worker_nodes_dns_names   = "${module.worker-nodes.workers_dns_names}"
  master_nodes_dns_names = "${module.master-nodes.masters_dns_names}"
  node_dns_names         = "${module.master-nodes.masters_dns_names}"
  internal_master_ips    = "${module.master-nodes.private_ip_addresses}"
  public_kubernetes_ip   = "${module.lb.public_ip_address}"
  kube_worker_node_names  = "${module.worker-nodes.names}"
  worker_node_ips         = "${module.worker-nodes.private_ip_addresses}"
  worker_username                = "${var.w_username}" 
  worker_password                = "${var.w_password}"
  api_server_username    = "${var.controller_username}"
  api_server_password    = "${var.controller_password}"
  nodes_count            = "${var.number_of_nodes}"
  ########################################
  # Enabling etcd cluster service
  #######################################
  controller_dns_names = "${module.master-nodes.masters_dns_names}"
  internal_master_private_ips    = "${module.master-nodes.private_ip_addresses}"
  controller_node_names   = "${module.master-nodes.names}"
  count = "${var.number_of_nodes}"
  ######################################################
  # boostrapping-kube-control-plane
  ######################################################
   
  
  
  ######################################################
  # expose-api-server-lb-rule
  ######################################################
  resource_group_name = "${module.kube_vnet.rsg_name}"
  protocol            = "${var.tcp_protocol}"
  loadbalancer_id     = "${module.lb.lb_id}"
  name                = "${var.lb_rule_name}"
  frontend_port   =     "${var.frontend_port}"
  backend_port    =     "${var.backend_port}"
  backend_ip_address_pool = "${module.lb.lb_backend_pool}"
  frontend_ip_configuration = "${var.lb_frontend_ip_conf_name}"
  ######################################################
  # api-server-version-health-check   
  ######################################################
  kubernetes_public_ip_address = "${module.lb.public_ip_address}"
  ####################################################################
  #bootstrapping-kube-worker-nodes
  ####################################################################
  worker_node_names = "${module.worker-nodes.names}" 
  ####################################################################  
  #worker-nodes-verification 
  ####################################################################
  # Create the pods cidr route table and deploy the core dns
  ####################################################################
  rsg_name = "${module.kube_vnet.rsg_name}"
  
  #rs_location = "${module.kube_vnet.rsg_location}"
  #subnet_id   = "${module.kube_vnet.subnet_id}"
  #vnet_subnet_name = "${module.kube_vnet.subnet_name}"
  #vnet_name   = "${module.kube_vnet.vnet_name}"  
}

resource "null_resource" "provisioning" {

    depends_on = ["module.certs"]

    # This is to test modules dependency
    provisioner "local-exec" {
        command = "echo done"
    }
}
/*
module "etcd" {
  source = "./az-kube-modules/kube-ecert-generation/kube-fetcd"
  controller_dns_names = "${module.master-nodes.masters_dns_names}"
  internal_master_private_ips    = "${module.master-nodes.private_ip_addresses}"
  api_server_username    = "${var.controller_username}"   
  api_server_password    = "${var.controller_password}"
  controller_node_names   = "${module.master-nodes.names}"
  count = "${var.number_of_nodes}"
}


module "boostrapping-kube-control-plane" {
  source = "./az-kube-modules/kube-gcontrol-plane"
  controller_dns_names         = "${module.master-nodes.masters_dns_names}"
  controller_node_names   = "${module.master-nodes.names}"
  internal_master_private_ips    = "${module.master-nodes.private_ip_addresses}"
  api_server_username    = "${var.controller_username}"
  api_server_password    = "${var.controller_password}"
  count = "${var.number_of_nodes}"
}

module "expose-api-server-lb-rule" {
  source = "./az-kube-modules/kube-lb-rules"
  resource_group_name = "${module.kube_vnet.rsg_name}"  
  protocol            = "${var.tcp_protocol}" 
  loadbalancer_id     = "${module.lb.lb_id}"
  name                = "${var.lb_rule_name}"
  frontend_port   =     "${var.frontend_port}"
  backend_port    =     "${var.backend_port}"
  backend_ip_address_pool = "${module.lb.lb_backend_pool}"
  frontend_ip_configuration = "${var.lb_frontend_ip_conf_name}"
  #"${module.lb.lb_frontend_ip_configuration_name}"
}

module "api-server-version_health-check" {
  source = "./az-kube-modules/verify-cluster-version"
  kubernetes_public_ip_address = "${module.lb.public_ip_address}"
} 

module "bootstrapping-kube-worker-nodes" {
  source = "./az-kube-modules/bootstrapping-kube-workers"
  worker_password = "${var.w_password}"
  worker_username = "${var.w_username}"
  worker_dns_names = "${module.worker-nodes.workers_dns_names}"
  worker_node_names = "${module.worker-nodes.names}"
  count            = "${var.number_of_nodes}"
}

module "worker-nodes-verification" {
  source = "./az-kube-modules/kube-workers-verification"
  api_server_username    = "${var.controller_username}"
  api_server_password    = "${var.controller_password}"
  controller_dns_names   = "${module.master-nodes.masters_dns_names}"
}
  
*/                                      
