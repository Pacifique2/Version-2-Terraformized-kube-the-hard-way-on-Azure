variable "lb_name" {
  default = "kube-lb"
}

variable "frontend_ip_configuration_name" {
  default = "KubePublicIPAddress"
}
variable "rs_location" {}
variable "rs_name" {}
variable "pip_name" {
  default = "terraform-kubernetes-pip"
}
variable "kube_az_tags" {
  type = "map"

  default {
    environment = "test-devolab"
  }
}

