#DR NOTES: 
#https://learn.microsoft.com/en-us/azure/storage/common/storage-disaster-recovery-guidance
#https://learn.microsoft.com/en-us/azure/storage/common/storage-failover-customer-managed-unplanned
#https://learn.microsoft.com/en-us/azure/storage/common/storage-initiate-account-failover

#Azure Machine Learning does not support default storage-account failover using geo-redundant storage (GRS),
# geo-zone-redundant storage (GZRS), read-access geo-redundant storage (RA-GRS), or read-access geo-zone-redundant storage (RA-GZRS). 
#Create a separate storage account for the default storage of each workspace.
#https://learn.microsoft.com/en-us/azure/machine-learning/how-to-high-availability-machine-learning?view=azureml-api-1#plan-for-multi-regional-deployment

resource "azurerm_user_assigned_identity" "sa" {
  for_each = {
    for key, value in local.storage_account.objects :
    key => value
    if value["create_customer_managed_key"] == true
  }
  name                = "mi-${local.name_base}-sa-${each.key}"
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  location            = var.PAIR_LOCATION
  tags                = merge(local.common_tags, {/*include tags here*/})
}

module "storage_account" {
  source = "../modules/storageaccount"
  for_each = {
    for key, value in local.storage_account.objects :
    key => value
    if value["shared_access_key_enabled"] == false
  }
  sa_name                           = "sa${local.name_base_no_dash}${each.key}"
  resource_group_name               = local.enablers_tfstate_output.resource_group_name
  location                          = var.PAIR_LOCATION
  tags                              = merge(local.common_tags, try(each.value.tags,{}))
  account_tier                      = each.value.account_tier
  environment_type                  = var.ENVIRONMENT_TYPE
  replication_type                  = each.value.replication_type
  account_kind                      = each.value.account_kind
  nfsv3_enabled                     = each.value.nfsv3_enabled
  is_hns_enabled                    = each.value.is_hns_enabled
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  key_vault_customer_managed_key_id = each.value.create_customer_managed_key ? azurerm_key_vault_key.keys["main_sa${local.name_base_no_dash}${each.key}"].versionless_id : null
    # TODO Determine if we need versionless key vault key id or not.
    # Currently Versionless is enabled
    # key_vault_key_id - (Required) The ID of the Key Vault Key, supplying a version-less key ID will enable auto-rotation of this key.
    # In case of enabling versionless, the attribute of azurerm_key_vault_key to be used would be versionless_id
    # In case of disabling versionless, the attribute of azurerm_key_vault_key to be used would be id
  user_assigned_identity_id         = each.value.create_customer_managed_key ? azurerm_user_assigned_identity.sa["${each.key}"].id : null
  role_mappings                     = each.value.role_mapping
  delete_retention_days             = local.storage_account.blob_delete_retention_days
  container_delete_retention_days   = local.storage_account.container_delete_retention_days
  public_network_access_enabled     = local.storage_account.public_network_access_enabled
  diagnostic_set_name               = local.storage_account.diagnostic_set_name
  diagnostic_set_id                 = local.storage_account.diagnostic_set_id
  ## Network Rules
  subnet_service_endpoints = each.value.subnet_service_endpoints
  default_network_rule     = local.storage_account.default_network_rule
  authorized_ips           = local.storage_account.authorized_ips
  traffic_bypass           = local.storage_account.traffic_bypass
  depends_on = [
    azurerm_key_vault_key.keys
  ]
}

module "storage_account_subresources" {
  source = "../modules/storageaccount_subresources"
  for_each = {
    for key, value in local.storage_account.objects :
    key => value
    if value["shared_access_key_enabled"] == false
  }
  storage_account_name = module.storage_account[each.key].name
  storage_account_id   = module.storage_account[each.key].id
  nfsv3_enabled        = each.value.nfsv3_enabled
  is_hns_enabled       = each.value.is_hns_enabled
  containers           = each.value.containers
  depends_on = [
    time_sleep.wait_for_sa_dns_a_records
  ]
}

module "storage_account_sas" {
  source = "../modules/storageaccount"
  for_each = {
    for key, value in local.storage_account.objects :
    key => value
    if value["shared_access_key_enabled"] == true
  }
  providers = {
    azurerm = azurerm.sas
  }
  sa_name                           = "sa${local.name_base_no_dash}${each.key}"
  resource_group_name               = local.enablers_tfstate_output.resource_group_name
  location                          = var.LOCATION
  tags                              = merge(local.common_tags, try(each.value.tags,{}))
  account_tier                      = each.value.account_tier
  environment_type                  = var.ENVIRONMENT_TYPE
  replication_type                  = each.value.replication_type
  account_kind                      = each.value.account_kind
  nfsv3_enabled                     = each.value.nfsv3_enabled
  is_hns_enabled                    = each.value.is_hns_enabled
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  key_vault_customer_managed_key_id = each.value.create_customer_managed_key ? azurerm_key_vault_key.keys["main_sa${local.name_base_no_dash}${each.key}"].versionless_id : null
  # TODO versionless key id, check previous TODO
  user_assigned_identity_id         = each.value.create_customer_managed_key ? azurerm_user_assigned_identity.sa["${each.key}"].id : null
  role_mappings                     = each.value.role_mapping
  delete_retention_days             = local.storage_account.blob_delete_retention_days
  container_delete_retention_days   = local.storage_account.container_delete_retention_days
  public_network_access_enabled     = local.storage_account.public_network_access_enabled
  diagnostic_set_name               = local.storage_account.diagnostic_set_name
  diagnostic_set_id                 = local.storage_account.diagnostic_set_id
  ## Network Rules
  default_network_rule     = local.storage_account.default_network_rule
  authorized_ips           = local.storage_account.authorized_ips
  subnet_service_endpoints = each.value.subnet_service_endpoints
  traffic_bypass           = local.storage_account.traffic_bypass
  depends_on = [
    azurerm_key_vault_key.keys
  ]
}

module "storage_account_subresources_sas" {
  source = "../modules/storageaccount_subresources"
  for_each = {
    for key, value in local.storage_account.objects :
    key => value
    if value["shared_access_key_enabled"] == true
  }
  providers = {
    azurerm = azurerm.sas
  }
  storage_account_name = module.storage_account_sas[each.key].name
  storage_account_id   = module.storage_account_sas[each.key].id
  nfsv3_enabled        = each.value.nfsv3_enabled
  is_hns_enabled       = each.value.is_hns_enabled
  containers           = each.value.containers
  depends_on = [
    time_sleep.wait_for_sa_dns_a_records
  ]
}

resource "azurerm_storage_management_policy" "management_policy" {
  for_each = {
    for sakey, savalue in local.storage_account.objects :
    sakey => savalue
    if savalue.storage_management_policy_enabled == true && length([for coname, covalue in savalue.containers : coname if covalue.include_in_management_policy]) > 0
  }
  storage_account_id = try(module.storage_account[each.key].id, module.storage_account_sas[each.key].id)
  rule {
    name    = "rule_${each.key}"
    enabled = true
    filters {
      prefix_match = [
        for coname, covalue in each.value.containers :
        "${coname}/*"
        if covalue.include_in_management_policy
      ]
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = local.storage_account.storage_management_policy_common.blob_tier_to_cool_after_days_since_modification_greater_than
        tier_to_archive_after_days_since_modification_greater_than = var.PAIR_PAAS && (each.key == "airflow" || each.key == "aml") ? null : 1825
        #If sa is set to RAGZRS, then an error appears when setting tier_to_archive_after_days_since_modification_greater_than
        delete_after_days_since_modification_greater_than = local.storage_account.storage_management_policy_common.blob_delete_after_days_since_modification_greater_than
      }
      snapshot {
        delete_after_days_since_creation_greater_than = local.storage_account.storage_management_policy_common.snapshot_delete_after_days_since_creation_greater_than
      }
    }
  }
}

resource "azurerm_management_lock" "sa" {
  for_each = {
    for key, value in local.storage_account.objects :
    key => value.management_lock.lock_level
    if value.management_lock.enabled == true
  }
  name       = local.storage_account.management_lock_common.name
  scope      = try(module.storage_account[each.key].id, module.storage_account_sas[each.key].id)
  lock_level = each.value
  notes      = local.storage_account.management_lock_common.notes
  depends_on = [
    azurerm_storage_management_policy.management_policy,
    module.storage_account_subresources,
    module.storage_account_subresources_sas
  ]
}

resource "null_resource" "sa_lock_delete" {
  triggers = {
    resource_group_name     = local.enablers_tfstate_output.resource_group_name_primary
    storage_account_dl      = local.infrastructure_tfstate_output.sa_name["dl"]
    # storage_account_vertica = local.infrastructure_tfstate_output.sa_name["vertica"]
    lock_name               = "lock-${local.name_base_primary}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
az lock delete --name ${self.triggers.lock_name} --resource-group ${self.triggers.resource_group_name} --resource ${self.triggers.storage_account_dl} --resource-type "Microsoft.Storage/storageAccounts"
EOT
#az lock delete --name ${self.triggers.lock_name} --resource-group ${self.triggers.resource_group_name} --resource ${self.triggers.storage_account_vertica} --resource-type "Microsoft.Storage/storageAccounts"
  }
  depends_on = [
    azurerm_private_dns_a_record.pe_sa
  ]
}

resource "null_resource" "sa_lock_create" {
  triggers = {
    resource_group_name     = local.enablers_tfstate_output.resource_group_name_primary
    storage_account_dl      = local.infrastructure_tfstate_output.sa_name["dl"]
    # storage_account_vertica = local.infrastructure_tfstate_output.sa_name["vertica"]
    lock_name               = "lock-${local.name_base_primary}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
az lock create --name ${self.triggers.lock_name} --resource-group ${self.triggers.resource_group_name} --resource ${self.triggers.storage_account_dl} --resource-type "Microsoft.Storage/storageAccounts" --lock-type CanNotDelete
EOT
#az lock create --name ${self.triggers.lock_name} --resource-group ${self.triggers.resource_group_name} --resource ${self.triggers.storage_account_vertica} --resource-type "Microsoft.Storage/storageAccounts" --lock-type CanNotDelete
  }
}