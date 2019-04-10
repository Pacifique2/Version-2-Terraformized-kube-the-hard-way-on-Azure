

/*                                                
data "azurerm_resource_group" "terraform_test" {
  name = "RG-Kube2"                             
}                                               
*/

resource "azurerm_availability_set" "zone" {
  name                = "${var.node}-${var.node_prefix}-as"
  location            = "${var.rs_location}"
  resource_group_name = "${var.rs_name}"

  managed = true

  tags = "${var.kube_az_tags}"
}

resource "azurerm_public_ip" "vm_pip" {
  count               = "${var.controller_count}"
  name                = "${var.node_prefix}-pip-${count.index}"
  location            = "${var.rs_location}"
  resource_group_name = "${var.rs_name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "master-dns-${count.index}"
  tags {         
      environment = "Terraform Demo"  
  }
}

resource "azurerm_network_interface" "main" {                                        
  count = "${var.controller_count}"
  name                = "${var.node_prefix}-${count.index}-nic"                                         
  location            = "${var.rs_location}"                   
  resource_group_name = "${var.rs_name}"                       
  enable_ip_forwarding = true  
                                                                                
  ip_configuration {                                                                
    name                          = "testconfiguration1"                            
    subnet_id                     = "${var.kube_subnet_id}"                 
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.root_ip}${count.index}"
    #public_ip_address_id          = "${element(azurerm_public_ip.vm_pip.*.id,count.index)}"
    public_ip_address_id          = "${length(azurerm_public_ip.vm_pip.*.id) > 0 ? element(concat(azurerm_public_ip.vm_pip.*.id, list("")), count.index) : ""}"
    #"${azurerm_public_ip.vm_pip.*.id[count.index]}"
    #load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.kube_lb_pool.id}"]
    load_balancer_backend_address_pools_ids = ["${var.lb_backend_pool}"]                                       
  }                                                               
}

/*                                                                                   
resource "azurerm_network_interface_backend_address_pool_association" "lb_backend_pool_nics" {
  count                   = "${var.controller_count}"
  network_interface_id    = "${azurerm_network_interface.main.*.id[count.index]}"
  ip_configuration_name   = "${var.node_prefix}-${count.index}-ip-config"
  backend_address_pool_id = "${var.lb_backend_pool}"
}
*/
/*
# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${data.azurerm_resource_group.terraform_test.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${data.azurerm_resource_group.terraform_test.name}"
    location                    = "westeurope"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Terraform Demo"
    }
}
  
 

resource "null_resource" "example2" {
  #var_ssh_agent = 
  provisioner "local-exec" {
    command = <<EOT 
      VAR_SSH_AGENT = $(ssh-agent -s)
      eval \$${VAR_SSH_AGENT}
      ssh-add ~/.ssh/kube-devolab_id_rsa 
      date > completed.txt
    EOT
    #interpreter = ["PowerShell", "-Command"]
  }
}
*/
                                                                              
resource "azurerm_virtual_machine" "main" {                                         
  count = "${var.controller_count}"
  name                  = "${var.node_prefix}-${count.index}"                                        
  location              = "${var.rs_location}"                 
  availability_set_id = "${azurerm_availability_set.zone.id}"
  resource_group_name   = "${var.rs_name}"                     
  # network_interface_ids = ["${azurerm_network_interface.main.id}"]   
  network_interface_ids = ["${azurerm_network_interface.main.*.id[count.index]}"]               
  vm_size               = "Standard_DS1_v2"                                         
                                                                                    
  # Uncomment this line to delete the OS disk automatically when deleting the VM    
  delete_os_disk_on_termination = true                                              
                                                                                    
                                                                                   
  # Uncomment this line to delete the data disks automatically when deleting the VM 
  delete_data_disks_on_termination = true                                           
                                                                                    
  storage_image_reference {                                                         
    publisher = "Canonical"                                                         
    offer     = "UbuntuServer"                                                      
    sku       = "18.04-LTS"                                                         
    version   = "latest"                                                            
  }                                                                                 
  storage_os_disk {                                                                 
    name              = "${var.node_prefix}-${count.index}-osdisk"                                                 
    caching           = "ReadWrite"                                                 
    create_option     = "FromImage"                                                 
    managed_disk_type = "Standard_LRS" 
    disk_size_gb      = 200                                             
  }                                                                                 
  os_profile {
    computer_name  = "${var.node_prefix}-${count.index}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/${var.username}/.ssh/authorized_keys"
      key_data = "${var.ssh_key_data}"
    }
  }
  tags = {
    environment = "Terraform Demo"
  }
  /*
  connection {
    type         = "ssh"
    user         = "${var.username}"
    host         = "${var.node_prefix}-${count.index}"
    # bastion_host = "${var.public_ip}"
  }
  */
  connection {
    type         = "ssh"
    host = "${element(azurerm_public_ip.vm_pip.*.fqdn,count.index)}"
    user         = "${var.username}"
    password     = "${var.password}"
    #agent        = false
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    #host        = "${var.node_prefix}-${count.index}"
    timeout      = "1m"
    agent        = true
    # host = "${element(azurerm_public_ip.vm_pip.*.fqdn,count.index)}"
    # "${var.worker_public_ip}"
  }
  provisioner "remote-exec" {
    inline = [
              "sudo apt-get update",
              "sudo apt-get install -y"
    ]
  } 
}


