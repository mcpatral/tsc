/*
output "aks_id" {
  value = {
    for key, value in module.aks : key => value.aks_cluster_id
  }
}

output "acr_id_aml" {
  value = local.infrastructure_tfstate_output.acr_id_aml
}

output "acr_name_aml" {
  value = local.infrastructure_tfstate_output.acr_name_aml
}

# TODO: Review usage of outputs below.
output "acr_login_server_aml" {
  description = "The URL that can be used to log into the container registry."
  value       = local.infrastructure_tfstate_output.acr_login_server_aml
}
*/
output "aks_cluster_name" {
  description = "AKS cluster name"
  value = {
    for key, value in module.aks : key => value.aks_cluster_name
  }
}

output "aks_cluster_resource_group_name" {
  description = "AKS cluster resource group name"
  value = {
    for key, value in module.aks : key => value.aks_cluster_resource_group_name
  }
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value = {
    for key, value in module.aks : key => value.aks_cluster_fqdn
  }
}

output "aks_cluster_pods_cidr" {
  description = "AKS cluster internal pods network CIDR"
  value = {
    for key, value in module.aks : key => value.aks_cluster_pods_cidr
  }
}

output "key_vault_name" {
  description = "Key vault names"
  value       = local.infrastructure_tfstate_output.key_vault_name
}

output "key_vault_uri" {
  description = "Key vault URIs"
  value       = local.infrastructure_tfstate_output.key_vault_uri
}

output "key_vault_id" {
  description = "Key vault IDs"
  value       = local.infrastructure_tfstate_output.key_vault_id
}

output "psql_server_name" {
  value = local.postgresql.name
}

output "psql_server_host" {
  value = "${local.postgresql.name}.postgres.database.azure.com"
}

output "psql_server_id" {
  value = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/${local.enablers_tfstate_output.resource_group_name}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${local.postgresql.name}"
}

/*
output "appinsights_id" {
  value = module.appinsights.id
}
*/

output "sa_id" {
  value       = merge(local.infrastructure_tfstate_output.sa_id, { for key, value in module.storage_account : key => value.id }, { for key, value in module.storage_account_sas : key => value.id })
  description = "The ID of the Storage Account."
}

output "sa_name" {
  value       = merge(local.infrastructure_tfstate_output.sa_name, { for key, value in module.storage_account : key => value.name }, { for key, value in module.storage_account_sas : key => value.name })
  description = "The name of the Storage Account."
}

# output "sa_container_vertica" {
#   value       = local.infrastructure_tfstate_output.sa_container_vertica
#   description = "Container created in Storage Account for Vertica"
# }

output "access_connector_id" {
  value = {
    for key, value in azurerm_databricks_access_connector.connector : key => value.id
  }
  description = "Managed identity id for databricks connection"
}

output "db_workspace_name" {
  value = module.databricks.db_workspace_name
}

output "db_workspace_host" {
  value = module.databricks.db_workspace_host
}

output "db_workspace_id" {
  value = module.databricks.db_workspace_id
}

output "databricks_id" {
  value = module.databricks.databricks_id
}