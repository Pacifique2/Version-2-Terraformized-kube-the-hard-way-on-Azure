/*
Provisioning Pod Network Routes
Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network routes.

# In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

There are other ways to implement the Kubernetes networking mode
The Routing Table
In this section you will gather the information required to create routes in the kubernetes-vnet.

Print the internal IP address and Pod CIDR range for each worker instance:


resource "azurerm_route_table" "testt" {
  count                         = "${var.count}"
  name                          = "kubernetes-routes"
  location                      = "${var.rs_location}"
  resource_group_name           = "${var.rsg_name}"
  disable_bgp_route_propagation = false
  depends_on  = ["null_resource.kubectl_testing"]
  route {
    name           = "kubernetes-route-10-200-${count.index}-0-24"
    address_prefix = "10.200.${count.index}.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.240.0.2${count.index}"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_route_table" "rtable" {
  name                          = "${var.route_table_name}"
  location                      = "${var.rs_location}"
  resource_group_name           = "${var.rsg_name}"
  disable_bgp_route_propagation = "${var.disable_bgp_route_propagation}"
}

resource "azurerm_route" "routes" {
  name                = "kubernetes-route-10-200-${count.index}-0-24"
  resource_group_name = "${var.rsg_name}"
  route_table_name    = "${azurerm_route_table.rtable.name}"
  address_prefix      = "10.200.${count.index}.0/24"
  next_hop_type       = "VirtualAppliance"
  count               = "${var.count}"
}
resource "azurerm_subnet_route_table_association" "test" {
  subnet_id      = "${var.subnet_id}"
  route_table_id = "${azurerm_route_table.test.id}"
}
*/
resource "null_resource" "list_pods_cidr_routes" {
  depends_on  = ["null_resource.kubectl_testing"]

  provisioner "local-exec" {
    command = "echo Routes"
    command = "echo 'network routes created for worker instance:'"

    #command = "az network vnet subnet update -g ${var.rsg_name} -n ${var.vnet_subnet_name} --vnet-name  ${var.vnet_name} --route-table kubernetes-routes"
    command = "az network route-table route list -g ${var.rsg_name} --route-table-name kubernetes-routes -o table"
    command = "echo 'done creating the pods routing table'"
  }
}

################################################
# Deploying the DNS Cluster Add-on
# In this lab we will deploy the DNS add-on which provides DNS based service discovery, backed by CoreDNS, to applications running inside the Kubernetes cluster.
########################################

resource "null_resource" "dns_add_on_deployment" {
  depends_on  = ["null_resource.list_pods_cidr_routes"]

  provisioner "local-exec" {
    command = "echo 'printing the internal IP address and Pod CIDR range for each worker instance:'"
    command = "kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml"
    command = "echo 'Deploy the coredns cluster add-on:'"
    command = "echo 'The DNS Cluster Add-on Deploy the coredns cluster add-on:'"
    command = "kubectl get pods -l k8s-app=kube-dns -n kube-system"
    command = "echo 'verification......................'"
    command = "kubectl run --generator=run-pod/v1 busybox --image=busybox:1.28 --command -- sleep 3600"
    command = "echo 'List the pod created by the busybox deployment:'"
    command = "kubectl get pods -l run=busybox"
    command = "echo 'Retrieve the full name of the busybox pod:'"
    command = "POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath='{.items[0].metadata.name}')"
    command = "echo 'Execute a DNS lookup for the kubernetes service inside the busybox pod:'"
    #command = "kubectl exec -ti $POD_NAME -- nslookup kubernetes"
  }
}
