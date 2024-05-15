#https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-security#3-the-azure-monitor-service-receives-and-processes-data
# In Log Analytics Workspace, the data is replicated within the local region using locally redundant storage (LRS).
resource "azurerm_log_analytics_workspace" "law_main" {
  count                      = var.AKS_OMS_AGENT_ENABLED || var.PAIR_CENTRAL_LAW_ID == null ? 1 : 0
  name                       = "law-${local.name_base}-main"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.PAIR_LOCATION
  tags                       = merge(local.common_tags, {/*include tags here*/})
  sku                        = var.LAW_SKU
  retention_in_days          = var.LAW_RETENTION_DAYS
  internet_ingestion_enabled = var.PAIR_CENTRAL_LAW_ID != null ? false : true
}

#A data collection endpoint (DCE) is a connection that the Logs ingestion API uses to send collected data for processing and ingestion into Azure Monitor.
resource "azurerm_monitor_data_collection_endpoint" "dce_main" {
  count                         = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                          = "dce-${local.name_base}-main"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = var.PAIR_LOCATION
  tags                          = merge(local.common_tags, {/*include tags here*/})
  kind                          = "Linux"
  public_network_access_enabled = false
  description                   = "Monitor data collection endpoint for ${var.PAIR_LOCATION} and Linux"
}

#Only a single AMPLS resource should be created for all networks that share the same DNS.
resource "azurerm_monitor_private_link_scoped_service" "pls_law" {
  count               = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                = "plss-${local.name_base}-law-main"
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  scope_name          = local.enablers_tfstate_output.pls_name
  linked_resource_id  = azurerm_log_analytics_workspace.law_main.0.id
}

resource "azurerm_monitor_private_link_scoped_service" "pls_dce" {
  count               = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                = "plss-${local.name_base}-dce-main"
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  scope_name          = local.enablers_tfstate_output.pls_name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce_main.0.id
}