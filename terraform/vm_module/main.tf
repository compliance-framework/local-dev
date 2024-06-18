resource "random_id" "compliance_framework_demo_random_id" {
  keepers = {
    my_key = "${var.iteration}-${var.vm_count}"
  }
  byte_length = 8
}

resource "azurerm_network_interface" "compliance_framework_demo_network_interface" {
  count               = var.vm_count
  name                = "example-nic-${random_id.compliance_framework_demo_random_id.hex}-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "compliance_framework_demo_virtual_machine" {
  count                 = var.vm_count
  name                  = "example-vm-${random_id.compliance_framework_demo_random_id.hex}-${count.index}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.compliance_framework_demo_network_interface[count.index].id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "example-osdisk-${random_id.compliance_framework_demo_random_id.hex}-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "example-vm-${random_id.compliance_framework_demo_random_id.hex}-${count.index}"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
