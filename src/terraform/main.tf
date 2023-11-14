terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "pt_resource" {
  name     = "pt_resource_vktask2_v2"
  location = "Central US"
}

resource "azurerm_virtual_network" "pt_virtual_network" {
    name                 = "pt_resource_vktask2_v2"
    address_space        = ["10.0.0.0/16"]
    location             = azurerm_resource_group.pt_resource.location
    resource_group_name  = azurerm_resource_group.pt_resource.name
}

resource "azurerm_subnet" "pt_subnet" {
    name                 = "internal"
    resource_group_name  = azurerm_resource_group.pt_resource.name
    virtual_network_name = azurerm_virtual_network.pt_virtual_network.name
    address_prefixes     = ["10.0.2.0/24"]
 }


resource "azurerm_public_ip" "pt_public_ip" {
  name                = "pt_public_ip_vktask2"
  location            = azurerm_resource_group.pt_resource.location
  resource_group_name = azurerm_resource_group.pt_resource.name
  allocation_method   = "Dynamic"

  tags = {
    environment ="test"
  }
}

data "azurerm_public_ip" "vm_public_ip" {
    name                = azurerm_public_ip.pt_public_ip.name
    resource_group_name = azurerm_resource_group.pt_resource.name
}

resource "azurerm_network_interface" "pt_network_interface" {
  name                = "pt_nic_vktask2"
  location            = azurerm_resource_group.pt_resource.location
  resource_group_name = azurerm_resource_group.pt_resource.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pt_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "pt_linux_vm" {
  name                = "SnipeITServer"
  resource_group_name = azurerm_resource_group.pt_resource.name
  location            = azurerm_resource_group.pt_resource.location
  size                = "Standard_B1s"
  admin_username      = "Varun"
  admin_password      = "Password@123"
  depends_on          = [azurerm_public_ip.pt_public_ip]
  custom_data         = base64encode(local.data_inputs)
  
  network_interface_ids = [
    azurerm_network_interface.pt_network_interface.id,
    ]

   admin_ssh_key {
    username   = "Varun"
    public_key = file("vk.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

output "public_ip_address" {
   value  = data.azurerm_public_ip.vm_public_ip.ip_address

}


locals {
  data_inputs = <<-EOT
    #!/bin/bash
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw reload

    git clone https://github.com/snipe/snipe-it             

    cd snipe-it

    ./install.sh <<EOF
      ${data.azurerm_public_ip.vm_public_ip.ip_address}
      y
      n
    EOF
  EOT
}