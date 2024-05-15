output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource group name"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "Resource group id"
}

output "resource_group_name_primary" {
  value       = local.enablers_tfstate_output.resource_group_name
  description = "Resource group name from primary region"
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

output "private_dns_zone_id" {
  value = local.enablers_tfstate_output.private_dns_zone_id
}

output "private_dns_zone_name" {
  value = local.enablers_tfstate_output.private_dns_zone_name
}

output "nsg_ids" {
  value = { for key in module.nsg : key.nsg_name => key.nsg_id }
}

output "acr_id_main" {
  value = local.enablers_tfstate_output.acr_id_main
}

output "acr_name_main" {
  value = local.enablers_tfstate_output.acr_name_main
}

output "aks_devops" {
  value = module.aks.aks_cluster_name
}

output "aks_devops_outbound_ip" {
  value = module.aks.aks_outbound_public_ip
}

output "aks_authorized_ips" {
  value = join(",", local.aks.api_server_authorized_ips)
}

output "aks_cluster_nodes_cidr_main" {
  description = "AKS main cluster subnet CIDR"
  value       = var.PAIR_SUBNET_AKS_PRIMARY_CIDR
}

output "aks_cluster_nodes_cidr_devops" {
  description = "AKS main cluster subnet CIDR"
  value       = var.PAIR_SUBNET_AKS_DEVOPS_CIDR
}

output "private_endpoints_cidr" {
  description = "Private Endpoints subnet CIDR"
  value       = var.PAIR_SUBNET_ENDPOINTS_CIDR
}

output "postgresql_cidr" {
  description = "PostgreSQL subnet CIDR"
  value       = var.PAIR_SUBNET_POSTGRES_CIDR
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
  value       = try(local.enablers_tfstate_output.pls_name, null)
}

output "pls_id" {
  description = "Log Analytics workspace id"
  value       = try(local.enablers_tfstate_output.pls_id, null)
}

output "data_collection_endpoint_id" {
  description = "Data Collection endpoint id"
  value       = try(azurerm_monitor_data_collection_endpoint.dce_main.0.id, null)
}