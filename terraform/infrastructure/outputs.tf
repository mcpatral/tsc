/*
output "aks_id" {
  value = {
    for key, value in module.aks : key => value.aks_cluster_id
  }
}

output "acr_id_aml" {
  value = module.acr.id
}

output "acr_name_aml" {
  value = module.acr.name
}

# TODO: Review usage of outputs below.
output "acr_login_server_aml" {
  description = "The URL that can be used to log into the container registry."
  value       = module.acr.login_server
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

output "key_vault_id" {
  description = "Key vault IDs"
  value = {
    for key, value in module.keyvault : key => value.key_vault_id
  }
}

output "key_vault_name" {
  description = "Key vault names"
  value = {
    for key, value in module.keyvault : key => value.key_vault_name
  }
}

output "key_vault_uri" {
  description = "Key vault URIs"
  value = {
    for key, value in module.keyvault : key => value.key_vault_uri
  }
}

output "psql_server_name" {
  value = local.postgresql.name
}

output "psql_server_host" {
  value = module.postgresql.postgresql_server_host
}

output "psql_server_id" {
  value = module.postgresql.postgresql_server_id
}

/*
output "appinsights_id" {
  value = module.appinsights.id
}
*/

output "sa_id" {
  value = {
    for key, value in merge(module.storage_account, module.storage_account_sas) : key => value.id
  }
  description = "The ID of the Storage Account."
}

output "sa_name" {
  value = {
    for key, value in merge(module.storage_account, module.storage_account_sas) : key => value.name
  }
  description = "The name of the Storage Account."
}

# output "sa_container_vertica" {
#   value       = "gaia${var.ENVIRONMENT_TYPE}"
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

output "aks_kubelet_identity_client_id" {
  value = module.aks["main"].aks_kubelet_identity_client_id
}