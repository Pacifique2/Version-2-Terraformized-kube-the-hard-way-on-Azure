variable "routes_count" {
  default = 3
}
variable "rsg_name" {
  default = "RG-Kube-Free"
}
variable "rs_location" {}
variable "subnet_id" {}
variable "disable_bgp_route_propagation" {}
variable "route_table_name" {
  default = "kubernetes-routes"
}
 
