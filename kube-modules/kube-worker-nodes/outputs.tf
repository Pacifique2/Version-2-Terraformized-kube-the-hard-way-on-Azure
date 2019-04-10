
output "names" {
  value = "${azurerm_virtual_machine.main.*.name}"
}

output "workers_dns_names" {
  value = "${azurerm_public_ip.vm_pip.*.fqdn}"
  #ip_address
}
#output "private_ip_addresses" {
#  value = "${azurerm_public_ip.vm_pip.*.private_ip_address}"
#}

output "private_ip_addresses" {
  value = "${azurerm_network_interface.main.*.private_ip_address}"
}

