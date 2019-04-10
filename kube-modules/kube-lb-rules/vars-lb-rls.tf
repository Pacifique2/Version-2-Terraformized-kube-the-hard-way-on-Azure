variable "resource_group_name" {}
variable "protocol" {}
variable "loadbalancer_id" {}
variable "name" {}
variable "frontend_port" {}
variable "backend_port" {}
variable "backend_ip_address_pool" {}
variable "frontend_ip_configuration" {
  default = "KubePublicIp"
}
