resource "random_password" "psql_compliant" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "psql_noncompliant" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "psqlserver_compliant" {
  name                = "psqlserver-compliant"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login    = "psqladmin"
  administrator_password = random_password.psql_compliant.result

  version             = "12"
  delegated_subnet_id = azurerm_subnet.db_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.dns.id
  zone                = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name = "GP_Standard_D2s_v3"

  backup_retention_days         = 7
  public_network_access_enabled = false
  high_availability {
    mode                      = "SameZone"
    standby_availability_zone = "1"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_vnet_link]
}

resource "azurerm_postgresql_flexible_server" "psqlserver_noncompliant" {
  name                = "psqlserver-noncompliant"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login    = "psqladmin"
  administrator_password = random_password.psql_noncompliant.result

  version = "12"
  zone    = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name = "GP_Standard_D2s_v3"

  public_network_access_enabled = true

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_vnet_link]
}
