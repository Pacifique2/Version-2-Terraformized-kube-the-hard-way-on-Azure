
output "names" {
  value = "${azurerm_virtual_machine.main.*.name}"
}

output "masters_dns_names" {
  value = "${azurerm_public_ip.vm_pip.*.fqdn}"
}
output "private_ip_addresses" {
  value = "${azurerm_network_interface.main.*.private_ip_address}"
}

