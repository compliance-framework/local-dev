provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-compliance-test"
  location = "UK South"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-compliance"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-compliance"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Custom security group
resource "azurerm_network_security_group" "custom_sg" {
  name                = "custom-sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Default security group (simulated by not defining custom rules)
resource "azurerm_network_security_group" "default_sg" {
  name                = "default-sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nic_compliant" {
  name                = "nic-compliant"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_compliant_sg" {
  network_interface_id      = azurerm_network_interface.nic_compliant.id
  network_security_group_id = azurerm_network_security_group.custom_sg.id
}

resource "azurerm_network_interface" "nic_non_compliant" {
  name                = "nic-non-compliant"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_non_compliant_sg" {
  network_interface_id      = azurerm_network_interface.nic_non_compliant.id
  network_security_group_id = azurerm_network_security_group.default_sg.id
}

resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "random_password" "vm_password" {
  length           = 16
  special         = true
}

resource "random_password" "vm_compliant" {
  length           = 16
  special         = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "vm_non_compliant" {
  length           = 16
  special         = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_linux_virtual_machine" "vm_compliant" {
  name                = "vm-compliant"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  admin_password      = random_password.vm_compliant.result
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic_compliant.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


resource "azurerm_linux_virtual_machine" "vm_non_compliant" {
  name                = "vm-non-compliant"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  admin_password      = random_password.vm_non_compliant.result
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic_non_compliant.id]

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

