provider "azurerm" {
  version = "1.28.0"
}

# Create a resource group
resource "azurerm_resource_group" "Johnrgter" {
  name     = "abcsa"
  location = "southeastasia"
}

resource "azurerm_storage_account" "testsa" {
  name                     = "john117117"
  resource_group_name      = azurerm_resource_group.Johnrgter.name
  location                 = azurerm_resource_group.Johnrgter.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }

}

//virtual network
resource "azurerm_virtual_network" "vn" {
  name                = "testsa"
  location            = azurerm_resource_group.Johnrgter.location
  resource_group_name = azurerm_resource_group.Johnrgter.name
  address_space       = ["10.0.0.0/16"]
}

//subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.Johnrgter.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefix       = "10.0.1.0/24"

}

resource "azurerm_public_ip" "ip" {
  name                = "PublicIp"
  location            = azurerm_resource_group.Johnrgter.location
  resource_group_name = azurerm_resource_group.Johnrgter.name
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "ni" {
  name                = "NI1-nic"
  location            = azurerm_resource_group.Johnrgter.location
  resource_group_name = azurerm_resource_group.Johnrgter.name

  ip_configuration {
    name                          = "TC1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "virtualmachine-vm"
  location              = azurerm_resource_group.Johnrgter.location
  resource_group_name   = azurerm_resource_group.Johnrgter.name
  network_interface_ids = [azurerm_network_interface.ni.id]
  vm_size               = "Standard_D2s_v3"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm1-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "ICG-KL"
    admin_username = "adminUsername"
    admin_password = "John-117"
  }
  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
  }
  boot_diagnostics {
    enabled     = "true"
    storage_uri = join(",", azurerm_storage_account.testsa.*.primary_blob_endpoint)
  }
}