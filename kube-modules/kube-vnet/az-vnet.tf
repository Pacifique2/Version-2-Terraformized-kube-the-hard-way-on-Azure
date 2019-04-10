resource "azurerm_resource_group" "terraform_test" {
  name     = "${var.rs_name}"
  location = "${var.rs_location}"

  tags = "${var.kube_az_tags}"
}
/*
resource "azurerm_managed_disk" "test" {  
  name                 = "managed_disk_name"   
  location             = "${data.azurerm_resource_group.test.location}"  
  resource_group_name  = "${data.azurerm_resource_group.test.name}" 
  storage_account_type = "Standard_LRS"   
  create_option        = "Empty"  
  disk_size_gb         = "1"
 } 


data "azurerm_resource_group" "terraform_test" {
  name = "RG-Kube2"
}
*/
resource "azurerm_virtual_network" "kube_az_vnet" {
  name                = "${var.az_vnet_name}-terraform"
  address_space       = ["${var.az_vnet_address_prefix[0]}"]
  location            = "${azurerm_resource_group.terraform_test.location}"
  resource_group_name = "${azurerm_resource_group.terraform_test.name}"
  /*subnet {
    name           = "${var.az_subnet_names[0]}"
    address_prefix = "${var.az_vnet_address_prefix[0]}"
        }
   */
  tags = "${var.kube_az_tags}"
}

 /*subnet {    
    name           = "${var.az_subnet_names[0]}"     
    address_prefix = "${var.az_vnet_address_prefix[0]}"   
   }
*/
resource "azurerm_subnet" "kube_vnet_subnet" {
  name                 = "${var.az_subnet_names[0]}"
  resource_group_name  = "${azurerm_resource_group.terraform_test.name}"
  virtual_network_name = "${azurerm_virtual_network.kube_az_vnet.name}"
  address_prefix       = "${var.az_vnet_address_prefix[0]}"
  network_security_group_id = "${azurerm_network_security_group.kube_sg.id}"
  route_table_id       = "${var.pods_route_table_id}"
}

resource "azurerm_subnet_network_security_group_association" "sg_association" {
  subnet_id                 = "${azurerm_subnet.kube_vnet_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.kube_sg.id}"
}

resource "azurerm_network_security_group" "kube_sg" {
  name                = "${var.az_vnet_name}-terrafm-sg"
  location            = "${azurerm_resource_group.terraform_test.location}"
  resource_group_name = "${azurerm_resource_group.terraform_test.name}"

  tags = "${var.kube_az_tags}"
}

resource "azurerm_network_security_rule" "inbound_ssh_connection" {
  name                        = "kube-allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.terraform_test.name}"
  network_security_group_name = "${azurerm_network_security_group.kube_sg.name}"
}

resource "azurerm_network_security_rule" "inbound_https_traffic" {
  name                        = "kube-allow-api-server-https"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.terraform_test.name}"
  network_security_group_name = "${azurerm_network_security_group.kube_sg.name}"
}

resource "azurerm_network_security_rule" "inbound_allow_all" {
  name                        = "kube-allow-all_inbound"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.240.0.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.terraform_test.name}"
  network_security_group_name = "${azurerm_network_security_group.kube_sg.name}"
}


resource "azurerm_network_security_rule" "outbound_allow_all" {                   
  name                        = "kube-allow-all_outbound"                                 
  priority                    = 103                                              
  direction                   = "Outbound"                                        
  access                      = "Allow"                                          
  protocol                    = "*"                                             
  source_port_range           = "*"                                              
  destination_port_range      = "*"                                              
  source_address_prefix       = "*"                                  
  destination_address_prefix  = "*"                                              
  resource_group_name         = "${azurerm_resource_group.terraform_test.name}"  
  network_security_group_name = "${azurerm_network_security_group.kube_sg.name}" 
}                                                                                
