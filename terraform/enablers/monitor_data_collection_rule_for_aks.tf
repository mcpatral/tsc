resource "azurerm_monitor_data_collection_rule_association" "aks_agents_pool_dce" {
  count                       = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                        = "configurationAccessEndpoint"
  target_resource_id          = module.aks.aks_cluster_id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce_main.0.id
  description                 = "Monitor data collection rule association for agents pool AKS and data collection endpoint"
}

resource "azurerm_monitor_data_collection_rule" "agents_pool" {
  count                       = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                        = "dcr-${local.name_base}-agents"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = var.LOCATION
  tags                        = merge(local.common_tags, local.monitor_resources_tags)
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce_main.0.id
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law_main.0.id
      name                  = "log-analytics-destination-log-${var.LOCATION}"
    }
  }
  data_flow {
    streams      = ["Microsoft-ContainerLogV2"]
    destinations = ["log-analytics-destination-log-${var.LOCATION}"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "aks_agents_pool_rule" {
  count                   = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                    = "dcra-${local.name_base}-aks-agents-pool-rule"
  target_resource_id      = module.aks.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.agents_pool.0.id
  description             = "Monitor data collection rule association for agents pool AKS and data collection rule"
}