/*
variable "controller_dns_names" {
  type = "list"
}
variable "api_server_username" {}
variable "api_server_password" {}
*/
variable "kube_controlller_binaries" {
  type = "string"
  description = "Creating Kubernetes config directory and installing the controller binaries"
  default = "Installing the kubernetes controller binaries ........."
}
/*
variable "controller_node_names" {
  type = "list"
}
variable "internal_master_private_ips" {
  type = "list"
}

variable "count" {}
*/
