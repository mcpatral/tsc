output "db_workspace_name" {
  value = azurerm_databricks_workspace.databricks.name
}

output "db_workspace_host" {
  value = azurerm_databricks_workspace.databricks.workspace_url
}

output "databricks_id" {
  value = azurerm_databricks_workspace.databricks.id
}

output "db_workspace_id" {
  value = azurerm_databricks_workspace.databricks.workspace_id
}
