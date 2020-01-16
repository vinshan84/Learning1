variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}
variable "resource_group" {}
variable "resource_prefix" {}
variable "Linux_address_spaces" {}
variable "subnet01-prefix" {}
variable "linux-private-vm" {}
variable "count" {}

provider "azurerm" {
    version         = "1.24.0"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
}

resource "azurerm_resource_group" "Web_Server_rg" {
  name              = "${var.resource_group}"
  location          = "southindia"
}

resource "azurerm_virtual_network" "linux_vnet" {
  name                  = "${var.resource_prefix}-vnet"
  resource_group_name   = "${azurerm_resource_group.Web_Server_rg.name}"
  location              = "southindia"
  address_space         = ["${var.Linux_address_spaces}"]
}

resource "azurerm_subnet" "linux_subnet" {
  name                  = "${var.resource_prefix}-subnet01"
  resource_group_name   = "${azurerm_resource_group.Web_Server_rg.name}"
  virtual_network_name  = "${azurerm_virtual_network.linux_vnet.name}"
  address_prefix        = "${var.subnet01-prefix}"
}

resource "azurerm_public_ip" "public_ip01" {
  name                  ="${var.resource_prefix}-public-ip"
  location              = "southindia"
  resource_group_name   = "${azurerm_resource_group.Web_Server_rg.name}"
  allocation_method     = "Dynamic"  
}

resource "azurerm_network_interface" "linux_vm_nic01" {
  name                  = "${var.resource_prefix}-nic01"
  resource_group_name   = "${azurerm_resource_group.Web_Server_rg.name}"
  location              = "southindia"

  ip_configuration {
    name                          = "${var.resource_prefix}-ip"
    subnet_id                     = "${azurerm_subnet.linux_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    private_ip_address            = "${var.linux-private-vm}"   
    public_ip_address_id          = "${azurerm_public_ip.public_ip01.id}"              
  }
}

resource "azurerm_network_security_group" "linux_vm_nsg" {
  name                            = "${var.resource_prefix}-nsg"
  location                        = "southindia"
  resource_group_name             = "${azurerm_resource_group.Web_Server_rg.name}"  
}

resource "azurerm_network_security_rule" "linux_vm_nsg" {
  name                        = "${var.resource_prefix}-nsg-rule"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.Web_Server_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.linux_vm_nsg.name}"
}
resource "azurerm_virtual_machine" "azurerm_vm" {
  name                            = "${var.resource_prefix}-VM"
  location                        = "southindia"
  resource_group_name             = "${azurerm_resource_group.Web_Server_rg.name}"  
  network_interface_ids           = ["${azurerm_network_interface.linux_vm_nic01.id}"]
  vm_size                         = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name                          = "myosdisk1"
    caching                       = "ReadWrite"
    create_option                 = "FromImage"
    managed_disk_type             = "Standard_LRS"
  }
  os_profile {
    computer_name                 = "Hostname"
    admin_username                = "webserver01"
    admin_password                = "Passw0rd1234"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}


