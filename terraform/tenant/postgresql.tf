resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = local.postgresql.database_name
  server_id = local.postgresql.server_id
  collation = local.postgresql.collation
  charset   = local.postgresql.charset
}
