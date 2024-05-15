resource "azurerm_monitor_workspace" "amw" {
  name                = var.amw_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                              = var.grafana_name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  api_key_enabled                   = var.grafana_api_key_enabled
  deterministic_outbound_ip_enabled = var.grafana_deterministic_outbound_ip_enabled
  public_network_access_enabled     = var.grafana_public_network_access_enabled
  tags                              = var.tags

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.amw.id
  }
}
