resource "random_password" "vm_compliant" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "vm_non_compliant" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_disk_encryption_set" "des" {
  name                = "des"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  key_vault_key_id    = azurerm_key_vault_key.des_key.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_linux_virtual_machine" "vm_compliant" {
  name                = "vm-compliant"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"

  admin_username                  = "azureuser"
  admin_password                  = random_password.vm_compliant.result
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.vm_nic_compliant.id]

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    disk_encryption_set_id = azurerm_disk_encryption_set.des.id
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    Environment   = "test"
    Security      = "totally_secure"
    Compliance    = "compliant"
    Application   = "app1"
    "Cost Center" = "finance"
    Project       = "project1"
    Owner         = "user1"
    Name          = "Me"
  }
}

resource "azurerm_linux_virtual_machine" "vm_non_compliant" {
  name                = "vm-non-compliant"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"

  admin_username                  = "azureuser"
  admin_password                  = random_password.vm_non_compliant.result
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
