# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "flexsrv" {
  name                              = var.psql_name
  resource_group_name               = var.rg_name
  location                          = var.location
  version                           = var.psql_version
  create_mode                       = var.create_mode
  delegated_subnet_id               = var.delegated_subnet_id
  private_dns_zone_id               = var.private_dns_zone_id
  administrator_login               = var.psql_admin_user
  administrator_password            = var.psql_admin_pwd
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  point_in_time_restore_time_in_utc = var.create_mode == "PointInTimeRestore" ? var.point_in_time_restore_time_in_utc : null
  source_server_id                  = var.create_mode == "PointInTimeRestore" || var.create_mode == "Replica" ? var.source_server_id : null
  zone                              = var.zone
  storage_mb                        = var.storage_mb
  sku_name                          = var.sku_name
  tags                              = var.tags
  authentication {
    active_directory_auth_enabled = true
    tenant_id                     = var.tenant_id
  }
  dynamic "high_availability" {
    for_each = var.high_availability_same_zone == false && var.high_availability_zone != null ? [var.high_availability_zone] : []
    content {
      mode = "ZoneRedundant"
      #standby_availability_zone = high_availability.value
    }
  }
  dynamic "high_availability" {
    for_each = var.high_availability_same_zone == true ? [var.high_availability_same_zone] : []
    content {
      mode = "SameZone"
    }
  }
  lifecycle {
    ignore_changes = [
      administrator_login,
      administrator_password,
      #create_mode #TODO remove this line when this issue is solved https://github.com/hashicorp/terraform-provider-azurerm/issues/16811
    ]
  }
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "psql_aad_admin" {
  server_name         = azurerm_postgresql_flexible_server.flexsrv.name
  resource_group_name = var.rg_name
  tenant_id           = var.tenant_id
  object_id           = var.object_id
  principal_name      = var.principal_name
  principal_type      = "ServicePrincipal"
}

resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.flexsrv.id
  collation = var.collation
  charset   = var.charset
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.flexsrv.id
  value     = var.max_connections
}
