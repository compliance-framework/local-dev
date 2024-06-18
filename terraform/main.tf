provider "azurerm" {
  features {}
}

variable "vm_repeats" {
  type    = number
  #default = 2  # Number of times to repeat the process
}

variable "vm_count" {
  type    = number
  #default = 3  # Number of VMs to create in each iteration
}

resource "azurerm_resource_group" "compliance_framework_demo_resource_group" {
  name     = "compliance-framework-demo-1"
  location = "East US"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network" "compliance_framework_demo_virtual_network" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.compliance_framework_demo_resource_group.location
  resource_group_name = azurerm_resource_group.compliance_framework_demo_resource_group.name
}

resource "azurerm_subnet" "compliance_framework_demo_subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.compliance_framework_demo_resource_group.name
  virtual_network_name = azurerm_virtual_network.compliance_framework_demo_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

module "vm" {
  source              = "./vm_module"
  for_each            = { for i in range(var.vm_repeats) : i => i }
  vm_count            = var.vm_count
  location            = azurerm_resource_group.compliance_framework_demo_resource_group.location
  resource_group_name = azurerm_resource_group.compliance_framework_demo_resource_group.name
  subnet_id           = azurerm_subnet.compliance_framework_demo_subnet.id
  iteration           = each.key
}
