variable "node_dns_names" {
  type = "list"  
}
variable "internal_master_ips" {
  type = "list"
}
variable "public_kubernetes_ip" {}
variable "kube_worker_node_names" {
  type = "list"
}
variable "worker_nodes_dns_names" {
  type = "list"
}
# variable "master_node_names" {}
variable "master_nodes_dns_names" {
  type = "list"
}
variable "worker_node_ips" {
  type = "list"
}
variable "worker_node_names" { 
  type = "list" 
}
variable  "worker_username" {}
variable "worker_password" {}
variable "api_server_username" {}
variable "api_server_password" {}

variable "nodes_count" {
  default = 3
}
variable "rsg_name" {
  default = "RG-Kube-Free"
}
#variable "rs_location" {}
#variable "subnet_id" {}
#variable "vnet_subnet_name" {} 
#variable "vnet_name" {}
