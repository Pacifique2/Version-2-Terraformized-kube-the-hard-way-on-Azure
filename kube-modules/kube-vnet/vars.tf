variable "pods_route_table_id" {}

variable "rs_location" {
  description = "The Azure location where the Resource Group should be located"
  default = "West Europe"
}

variable "rs_name" {
  default = "RG-Kube-Free"
}
variable "az_vnet_name" {
  default = "kube-vnet"
}
variable "az_subnet_names" {
  type = "list"
  default = ["kube-subnet"]
}
variable "az_subnet_add_prefix" {
  default = "10.240.0.0/24"
}
variable "az_vnet_address_prefix" {
  type = "list"
  default = ["10.240.0.0/24"]
}

variable "kube_az_tags" {
  type = "map"

  default {
    environment = "Kube-terraform-Devoteam"
  }
}
