variable "rs_location" {
  description = "The Azure location where the Resource Group should be located"
}

variable "rs_name" {}

variable "node_prefix" {
  description = "The prefix to use for all the controllers' VM names"
  default = "kube-node"
}

variable "node" {}
/*
variable "controller_count" {
  description = "The count of controller VMs to create"
  #default = 3
}
*/
variable "worker_count" {
  description = "The count of worker nodes to create"
  default = 2
}
/*

variable "lb_backend_pool" {
  default     = ""
  description = "The Load Balancer backend pool to attach the VM NICs to"
}
*/
variable "kube_subnet_id" {
  description = "The subnet ID to place the VM NICs into"
}

variable "ssh_key_data" {
  description = "The public SSH key to provision to the instance user"
    #default   = "${file("~/.ssh/kube-devolab_id_rsa.pub")}"
}

variable "username" {}
variable "password" {}
variable "root_ip" {}

variable "kube_az_tags" {
  type = "map"

  default {
    POD_CIDR = "10.200.0.0/24"
    #environment = "Test-DevoLab"
  }
}

