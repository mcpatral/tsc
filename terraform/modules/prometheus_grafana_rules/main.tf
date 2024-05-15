resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "MSProm-${var.aks_cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = "MSProm-${var.aks_cluster_name}"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
  kind                        = "Linux"
  tags                        = var.tags

  destinations {
    monitor_account {
      monitor_account_id = var.amw_id
      name               = "MonitoringAccount-${var.aks_cluster_name}"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount-${var.aks_cluster_name}"]
  }


  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  depends_on = [
    azurerm_monitor_data_collection_endpoint.dce
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "MSProm-${var.location}-${var.aks_cluster_name}"
  target_resource_id      = var.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  description             = "Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster."
  depends_on = [
    azurerm_monitor_data_collection_rule.dcr
  ]
}
