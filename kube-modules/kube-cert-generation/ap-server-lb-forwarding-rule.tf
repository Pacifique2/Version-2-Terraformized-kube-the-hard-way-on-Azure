

#############################################
# he Kubernetes Frontend Load Balancer
# In this section you will provision an external load balancer to front the Kubernetes API Servers.
# The kubernetes-the-hard-way static IP address will be attached to the resulting load balancer.

# The compute instances created in this tutorial will not have permission to complete this section. 
# Run the following commands from the same machine used to create the compute instances.

# Create the load balancer health probe as a pre-requesite for the lb rule that follows.
##############################################

resource "azurerm_lb_probe" "probe" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${var.loadbalancer_id}"
  name                = "${var.backend_port}-kubernetes-apiserver-probe"
  port                = "${var.backend_port}"
}

resource "azurerm_lb_rule" "lb" {
  depends_on = ["null_resource.cluster_role_binding"]
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${var.loadbalancer_id}"
  name                           = "${var.name}"
  protocol                       = "${var.protocol}"
  frontend_port                  = "${var.frontend_port}"
  backend_port                   = "${var.backend_port}"
  frontend_ip_configuration_name = "${var.frontend_ip_configuration}"
  backend_address_pool_id        = "${var.backend_ip_address_pool}"
  probe_id                       = "${azurerm_lb_probe.probe.id}"
}
