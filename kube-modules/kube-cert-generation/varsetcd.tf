variable "count" {
 default = 2
}

variable "controller_dns_names" {
  type = "list"
}
#variable "api_server_username" {}
#variable "api_server_password" {}
variable "controller_node_names" {
  type = "list"
}
/*
variable "kubernetes_certs_null_ids" {
  type        = "list"
  description = "The ID of the kubernetes apiserver certificate null resource id for dependency"
}

variable "ca_cert_null_ids" {
  type        = "list"
  description = "The ID of the CA certificate null resource id for dependency"
}

variable "apiserver_node_names" {
  type        = "list"
  description = "The list of nodes that will have etcd installed"
}
*/
variable "internal_master_private_ips" {
  type        = "list"
  description = "The list of IP addresses that will have etcd installed"
}
