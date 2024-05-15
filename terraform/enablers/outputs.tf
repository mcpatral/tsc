output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource group name"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "Resource group id"
}

output "networks_vnet_id" {
  value = module.vnet.vnet_id
}

output "networks_vnet_name" {
  value = module.vnet.vnet_name
}

output "networks_vnet_subnets" {
  value = module.vnet.vnet_subnets
}

output "endpoints_subnet_id" {
  value = module.vnet.vnet_subnets["subnet-${local.name_base}-${local.subnet_key_names.endpoints}"]
}

output "managed_private_dns_zone_id" {
  value = { for key, value in module.private_dns_zone : key => value.dns_zone_id }
}

output "managed_private_dns_zone_name" {
  value = { for key, value in module.private_dns_zone : key => value.dns_zone }
}

output "hub_private_dns_zone_name" {
  value = { for key, value in local.private_dns_zones_hub : key => value.name }
}

output "hub_private_dns_zone_resource_group_name" {
  value = var.HUB_DNS_RESOURCE_GROUP_NAME
}

output "private_dns_zone_name" {
  value = { for key, value in merge(local.private_dns_zones_hub, local.private_dns_zones_internal) : key => value.name }
}

output "mi_id_aks_main" {
  value = azurerm_user_assigned_identity.managed_identity["aks_primary"].id
}

output "nsg_ids" {
  value = { for key in module.nsg : key.nsg_name => key.nsg_id }
}

output "acr_id_main" {
  value = module.acr.id
}

output "acr_name_main" {
  value = module.acr.name
}

output "aks_devops_name" {
  value = module.aks.aks_cluster_name
}

output "aks_devops_id" {
  value = module.aks.aks_cluster_id
}

output "aks_devops_outbound_ip" {
  value = var.VNET_PEERED ? var.FIREWALL_PUBLIC_IP : module.aks.aks_outbound_public_ip
}

output "aks_authorized_ips" {
  value = join(",", local.aks.api_server_authorized_ips)
}

output "aks_cluster_nodes_cidr_main" {
  description = "AKS main cluster subnet CIDR"
  value       = var.SUBNET_AKS_PRIMARY_CIDR
}

output "aks_cluster_nodes_cidr_devops" {
  description = "AKS main cluster subnet CIDR"
  value       = var.SUBNET_AKS_DEVOPS_CIDR
}

output "private_endpoints_cidr" {
  description = "Private Endpoints subnet CIDR"
  value       = var.SUBNET_ENDPOINTS_CIDR
}

output "postgresql_cidr" {
  description = "PostgreSQL subnet CIDR"
  value       = var.SUBNET_POSTGRES_CIDR
}

output "intrum_vpn_cidrs" {
  description = "Intrum VPN subnet CIDR"
  value       = { for index, value in local.intrum_vpn_cidrs : "rule${index}" => value }
}

output "azurerm_monitor_workspace_id" {
  description = "Azure monitor worspace ID"
  value       = try(module.prometheus_grafana.0.azurerm_monitor_workspace_id, null)
}

output "law_main_id" {
  description = "Log Analytics workspace id"
  value       = try(azurerm_log_analytics_workspace.law_main.0.id, null)
}

output "pls_name" {
  description = "Private link scope name"
  value       = try(azurerm_monitor_private_link_scope.pls.0.name, null)
}

output "pls_id" {
  description = "Log Analytics workspace id"
  value       = try(azurerm_monitor_private_link_scope.pls.0.id, null)
}

output "data_collection_endpoint_id" {
  description = "Data Collection endpoint id"
  value       = try(azurerm_monitor_data_collection_endpoint.dce_main.0.id, null)
}

output "prometheus_grafana_tags" {
  description = "Tags assigned to Prometheus and Grafana resources"
  value       = local.prometheus_grafana.tags
}

output "monitor_resources_tags" {
  description = "Tags assigned to Monitor resources"
  value       = local.monitor_resources_tags
}
