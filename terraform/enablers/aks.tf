resource "azurerm_user_assigned_identity" "managed_identity" {
  for_each            = local.managed_identities
  name                = "mi-${local.name_base}-${each.value}"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "mi" {
  for_each                         = local.managed_identities_assignments
  principal_id                     = azurerm_user_assigned_identity.managed_identity[each.value.mi_key].principal_id
  role_definition_name             = each.value.role
  scope                            = each.value.scope
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}

module "aks" {
  source                    = "../modules/aks"
  name                      = "aks-${local.name_base}-${local.aks.name}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = var.LOCATION
  tags                      = merge(local.common_tags, local.aks.tags)
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
  cluster_node_pools        = local.aks_cluster_node_pools
  acr_id                    = module.acr.id
  vnet_id                   = module.vnet.vnet_id
  identity_type             = local.aks.identity_type
  identity_id               = azurerm_user_assigned_identity.managed_identity["devops"].id
  diagnostic_law_id         = var.AKS_OMS_AGENT_ENABLED ? azurerm_log_analytics_workspace.law_main.0.id : var.CENTRAL_LAW_ID
  oms_agent_enabled         = var.AKS_OMS_AGENT_ENABLED
  depends_on = [
    azurerm_private_dns_a_record.pe,
    azurerm_private_dns_a_record.pe_hub,
    azurerm_role_assignment.mi
  ]
}