module "prometheus_grafana" {
  source                                    = "../modules/prometheus_grafana"
  count                                     = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  amw_name                                  = "amw-${local.name_base}"
  grafana_name                              = "grafana-${local.name_base}"
  location                                  = var.LOCATION
  resource_group_name                       = azurerm_resource_group.rg.name
  tags                                      = merge(local.common_tags, local.prometheus_grafana.tags)
  resource_group_id                         = azurerm_resource_group.rg.id
  aks_cluster_name                          = module.aks.aks_cluster_name
  aks_cluster_id                            = module.aks.aks_cluster_id
  grafana_admin_group_ids                   = local.prometheus_grafana.roles.admin_group_ids
  grafana_editor_group_ids                  = local.prometheus_grafana.roles.editor_group_ids
  grafana_viewer_group_ids                  = local.prometheus_grafana.roles.viewer_group_ids
  grafana_api_key_enabled                   = local.prometheus_grafana.grafana_api_key_enabled
  grafana_deterministic_outbound_ip_enabled = local.prometheus_grafana.grafana_deterministic_outbound_ip_enabled
  grafana_public_network_access_enabled     = local.prometheus_grafana.grafana_public_network_access_enabled
}

module "prometheus_grafana_rules" {
  source              = "../modules/prometheus_grafana_rules"
  count               = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  aks_cluster_name    = module.aks.aks_cluster_name
  aks_cluster_id      = module.aks.aks_cluster_id
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.rg.name
  resource_group_id   = azurerm_resource_group.rg.id
  tags                = merge(local.common_tags, local.prometheus_grafana.tags)
  amw_id              = try(module.prometheus_grafana.0.azurerm_monitor_workspace_id, null)
}
