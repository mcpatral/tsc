module "prometheus_grafana_rules" {
  source              = "../modules/prometheus_grafana_rules"
  count               = var.AKS_OMS_AGENT_ENABLED ? 1 : 0
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  location            = var.LOCATION
  tags                = merge(local.common_tags, local.enablers_tfstate_output.prometheus_grafana_tags)
  resource_group_id   = local.enablers_tfstate_output.resource_group_id
  amw_id              = local.enablers_tfstate_output.azurerm_monitor_workspace_id
  aks_cluster_name    = module.aks["main"].aks_cluster_name
  aks_cluster_id      = module.aks["main"].aks_cluster_id
}
