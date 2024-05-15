output "azurerm_monitor_workspace_id" {
  description = "Azure monitor worspace ID"
  value       = azurerm_monitor_workspace.amw.id
}

output "grafana_url" {
  description = "Dashboard grafana url"
  value       = azurerm_dashboard_grafana.grafana.endpoint
}