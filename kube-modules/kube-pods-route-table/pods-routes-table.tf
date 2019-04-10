resource "azurerm_route_table" "route_table" {
  name                          = "${var.route_table_name}"
  location                      = "${var.rs_location}"
  resource_group_name           = "${var.rsg_name}"
  disable_bgp_route_propagation = "${var.disable_bgp_route_propagation}"
}

resource "azurerm_route" "routes" {
  name                = "kubernetes-route-10-200-${count.index}-0-24"
  resource_group_name = "${var.rsg_name}"
  route_table_name    = "${azurerm_route_table.route_table.name}"
  address_prefix      = "10.200.${count.index}.0/24"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = "10.240.0.2${count.index}"
  count               = "${var.routes_count}"
}
resource "azurerm_subnet_route_table_association" "test" {
  subnet_id      = "${var.subnet_id}"
  route_table_id = "${azurerm_route_table.route_table.id}"
}
