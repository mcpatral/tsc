module "aks" {
  source                    = "../modules/aks"
  name                      = "aks-${local.name_base}-${local.aks.name}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = var.PAIR_LOCATION
  tags                      = merge(local.common_tags, try(local.aks.tags, {}))
  sku                       = local.aks.sku
  admin_username            = local.aks.admin_username
  kubernetes_version        = local.aks.kubernetes_version
  api_server_authorized_ips = local.aks.api_server_authorized_ips
  network_plugin            = local.aks.network_plugin
  network_policy            = local.aks.network_policy
  network_pod_cidr          = local.aks.network_pod_cidr
  open_service_mesh_enabled = local.aks.open_service_mesh_enabled
  private_cluster_enabled   = local.aks.private_cluster_enabled
  dns_prefix                = local.aks.dns_prefix
  network_lb_sku            = local.aks.network_lb_sku
  network_outbound_type     = local.aks.network_outbound_type
  default_node_pool         = local.aks_default_node_pool
  acr_id                    = local.enablers_tfstate_output.acr_id_main
  vnet_id                   = module.vnet.vnet_id
  diagnostic_law_id         = var.AKS_OMS_AGENT_ENABLED ? azurerm_log_analytics_workspace.law_main.0.id : var.PAIR_CENTRAL_LAW_ID
  oms_agent_enabled         = var.AKS_OMS_AGENT_ENABLED
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.dns_link,
    azurerm_private_dns_a_record.pe["acr_main"],
    null_resource.delete_create_a_records["acr_main.northeurope.data"]
  ]
}