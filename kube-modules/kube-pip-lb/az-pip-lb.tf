
/*
data "azurerm_resource_group" "terraform_test" {
  name = "RG-Kube2"                             
}                                               
*/
resource "azurerm_public_ip" "kube_pip" {
  name                = "${var.rs_name}-${var.pip_name}"
  location            = "${var.rs_location}"
  resource_group_name = "${var.rs_name}"
  allocation_method   = "Static"

  tags = "${var.kube_az_tags}"
}

resource "azurerm_lb" "kube_lb" {
  name                = "${var.rs_name}-${var.lb_name}"
  location            = "${var.rs_location}"
  resource_group_name = "${var.rs_name}"

  frontend_ip_configuration {
    name                 = "${var.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.kube_pip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "kube_lb_pool" {
  resource_group_name = "${var.rs_name}"
  loadbalancer_id     = "${azurerm_lb.kube_lb.id}"
  name                = "kube-lb-pool"
}

