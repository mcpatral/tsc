resource "azurerm_monitor_data_collection_rule_association" "aks_main_dce" {
  count                       = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                        = "configurationAccessEndpoint"
  target_resource_id          = module.aks["main"].aks_cluster_id
  data_collection_endpoint_id = local.enablers_tfstate_output.data_collection_endpoint_id
  description                 = "Monitor data collection rule association for main AKS and data collection endpoint"
}

resource "azurerm_monitor_data_collection_rule" "main" {
  count                       = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                        = "dcr-${local.name_base}"
  resource_group_name         = local.enablers_tfstate_output.resource_group_name
  location                    = var.LOCATION
  tags                        = merge(local.common_tags, local.enablers_tfstate_output.monitor_resources_tags)
  data_collection_endpoint_id = local.enablers_tfstate_output.data_collection_endpoint_id
  destinations {
    log_analytics {
      workspace_resource_id = local.enablers_tfstate_output.law_main_id
      name                  = "log-analytics-destination-log-${var.LOCATION}"
    }
    # azure_monitor_metrics {
    #   name = "azure-monitor-metrics-destination-metrics-${var.LOCATION}"
    # }
  }
  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"] #["Microsoft-ContainerLogV2", "Microsoft-Event", "Microsoft-InsightsMetrics", "Microsoft-Perf", "Microsoft-Syslog"]
    destinations = ["log-analytics-destination-log-${var.LOCATION}"]
  }
  #   data_flow {
  #     streams      = ["Microsoft-InsightsMetrics"]
  #     destinations = ["azure-monitor-metrics-destination-metrics-${var.LOCATION}"]
  #   }
  data_sources {
    extension {
      name    = "ContainerInsightsExtension"
      streams = ["Microsoft-ContainerInsights-Group-Default"]
      # Available streams:
      #     "Microsoft-Perf",
      #     "Microsoft-InsightsMetrics",
      #     "Microsoft-ContainerLog",
      #     "Microsoft-ContainerLogV2",
      #     "Microsoft-KubeEvents",
      #     "Microsoft-KubePodInventory",
      #     "Microsoft-ContainerInventory",
      #     "Microsoft-ContainerNodeInventory",
      #     "Microsoft-KubeNodeInventory",
      #     "Microsoft-KubeServices",
      #     "Microsoft-KubePVInventory",
      #     "Microsoft-KubeHealth",
      #     "Microsoft-KubeMonAgentEvents"
      extension_name = "ContainerInsights"
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "5m"
          namespaceFilteringMode = "Include"
          namespaces             = ["airflow"]
          enableContainerLogV2   = true
        }
      })
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "aks_main_rule" {
  count                   = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  name                    = "dcra-${local.name_base}-aks-main-rule"
  target_resource_id      = module.aks["main"].aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.main.0.id
  description             = "Monitor data collection rule association for main AKS and data collection rule"
}