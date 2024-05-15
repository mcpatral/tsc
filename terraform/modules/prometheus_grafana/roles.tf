#Add required role assignment over resource group containing the Azure Monitor Workspace
resource "azurerm_role_assignment" "grafana" {
  scope                = var.resource_group_id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
  depends_on = [
    azurerm_dashboard_grafana.grafana
  ]
}

resource "azurerm_role_assignment" "datareaderrole" {
  scope              = azurerm_monitor_workspace.amw.id
  role_definition_id = local.amw_role_definition_id
  principal_id       = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}

# Add role assignment to Grafana so an admin user can log in
resource "azurerm_role_assignment" "grafana_admin" {
  for_each             = var.grafana_admin_group_ids
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = each.value
  depends_on = [
    azurerm_dashboard_grafana.grafana
  ]
}

resource "azurerm_role_assignment" "grafana_editor" {
  for_each             = var.grafana_editor_group_ids
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Editor"
  principal_id         = each.value
  depends_on = [
    azurerm_dashboard_grafana.grafana
  ]
}

resource "azurerm_role_assignment" "grafana_viewer" {
  for_each             = var.grafana_viewer_group_ids
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Viewer"
  principal_id         = each.value
  depends_on = [
    azurerm_dashboard_grafana.grafana
  ]
}
