output "public_ip_address" {
  value = "${azurerm_public_ip.kube_pip.ip_address}"
}

output "lb_backend_pool" {
  value = "${azurerm_lb_backend_address_pool.kube_lb_pool.id}"
}

output "lb_id" {
  value = "${azurerm_lb.kube_lb.id}" 
}
/*
output "lb_frontend_ip_configuration_name" {
  value = " ${azurerm_lb.kube_lb.frontend_ip_configuration.name}"
}
*/
