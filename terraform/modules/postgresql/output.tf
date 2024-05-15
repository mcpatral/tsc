output "postgresql_db_ai_name" {
  value = azurerm_postgresql_flexible_server_database.database.name
}
output "postgresql_server_host" {
  value = azurerm_postgresql_flexible_server.flexsrv.fqdn
}
output "postgresql_server_id" {
  value = azurerm_postgresql_flexible_server.flexsrv.id
}
