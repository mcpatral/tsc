#TODO: Consider following these best practises for DR https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-multi-region
module "aks" {
  for_each                            = local.aks_clusters
  source                              = "../modules/aks"
  name                                = "aks-${local.name_base}-${each.key}"
  resource_group_name                 = local.enablers_tfstate_output.resource_group_name
  location                            = var.LOCATION
  tags                                = merge(local.common_tags, each.value.tags)
  sku                                 = local.aks.sku
  admin_username                      = local.aks.admin_username
  kubernetes_version                  = local.aks.kubernetes_version
  vnet_id                             = local.aks.vnet_id
  private_cluster_enabled             = local.aks.private_cluster_enabled
  private_cluster_public_fqdn_enabled = local.aks.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = local.aks.private_dns_zone_id
  network_plugin                      = local.aks.network_plugin
  network_policy                      = local.aks.network_policy
  open_service_mesh_enabled           = local.aks.open_service_mesh_enabled
  api_server_authorized_ips           = local.aks.api_server_authorized_ips
  acr_id                              = each.value.acr_id
  dns_prefix                          = each.value.dns_prefix
  identity_type                       = each.value.identity_type
  identity_id                         = each.value.identity_id
  network_outbound_type               = local.aks.network_outbound_type
  network_pod_cidr                    = each.value.network_pod_cidr
  oidc_issuer_enabled                 = each.value.oidc_issuer_enabled
  oms_agent_enabled                   = each.value.oms_agent_enabled
  workload_identity_enabled           = each.value.workload_identity_enabled
  default_node_pool                   = each.value.default_node_pool
  cluster_node_pools                  = each.value.cluster_node_pools
  diagnostic_law_id                   = each.value.oms_agent_enabled ? local.enablers_tfstate_output.law_main_id : var.CENTRAL_LAW_ID
}