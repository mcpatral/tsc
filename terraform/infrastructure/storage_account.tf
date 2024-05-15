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
  location            = var.LOCATION
  tags                = merge(local.common_tags, local.mi_sa_tags)
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
  location                          = var.LOCATION
  tags                              = merge(local.common_tags, each.value.tags)
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
  user_assigned_identity_id       = each.value.create_customer_managed_key ? azurerm_user_assigned_identity.sa["${each.key}"].id : null
  role_mappings                   = var.SA_TEST_USER_ENABLED ? merge(each.value.role_mapping, each.value.test_role_mapping) : each.value.role_mapping
  delete_retention_days           = local.storage_account.blob_delete_retention_days
  container_delete_retention_days = local.storage_account.container_delete_retention_days
  public_network_access_enabled   = local.storage_account.public_network_access_enabled
  ## Network Rules
  subnet_service_endpoints            = each.value.subnet_service_endpoints
  default_network_rule                = local.storage_account.default_network_rule
  authorized_ips                      = local.storage_account.authorized_ips
  traffic_bypass                      = each.value.traffic_bypass
  databricks_access_connector_id      = azurerm_databricks_access_connector.connector["dbac-${local.name_base}-extloc"].id
  databricks_connector_assign_sa_list = ["sa${local.name_base_no_dash}dl", "sa${local.name_base_no_dash}temp"]
  depends_on = [
    azurerm_key_vault_key.keys
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
  tags                              = merge(local.common_tags, each.value.tags)
  account_tier                      = each.value.account_tier
  environment_type                  = var.ENVIRONMENT_TYPE
  replication_type                  = each.value.replication_type
  account_kind                      = each.value.account_kind
  nfsv3_enabled                     = each.value.nfsv3_enabled
  is_hns_enabled                    = each.value.is_hns_enabled
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  key_vault_customer_managed_key_id = each.value.create_customer_managed_key ? azurerm_key_vault_key.keys["main_sa${local.name_base_no_dash}${each.key}"].versionless_id : null
  # TODO versionless key id, check previous TODO
  user_assigned_identity_id       = each.value.create_customer_managed_key ? azurerm_user_assigned_identity.sa["${each.key}"].id : null
  role_mappings                   = var.SA_TEST_USER_ENABLED ? merge(each.value.role_mapping, each.value.test_role_mapping) : each.value.role_mapping
  delete_retention_days           = local.storage_account.blob_delete_retention_days
  container_delete_retention_days = local.storage_account.container_delete_retention_days
  public_network_access_enabled   = local.storage_account.public_network_access_enabled
  ## Network Rules
  default_network_rule                = local.storage_account.default_network_rule
  authorized_ips                      = local.storage_account.authorized_ips
  subnet_service_endpoints            = each.value.subnet_service_endpoints
  traffic_bypass                      = each.value.traffic_bypass
  databricks_access_connector_id      = azurerm_databricks_access_connector.connector["dbac-${local.name_base}-extloc"].id
  databricks_connector_assign_sa_list = ["sa${local.name_base_no_dash}dl", "sa${local.name_base_no_dash}temp"]
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
    time_sleep.wait_for_sa_dns_a_records_to_propagate
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
    time_sleep.wait_for_sa_dns_a_records_to_propagate
  ]
}

resource "azurerm_storage_management_policy" "management_policy" {
  for_each           = local.storage_accounts_lifecycle_managment
  storage_account_id = each.value

  dynamic "rule" {
    for_each = local.lifecycle_managment_rules[each.key]
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      dynamic "filters" {
        for_each = rule.value.filters
        content {
          prefix_match = filters.value.prefix_match
          blob_types   = filters.value.blob_types
        }
      }
      actions {
        base_blob {
          delete_after_days_since_modification_greater_than = rule.value.actions.base_blob.delete_after_days
        }
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
    azurerm_monitor_diagnostic_setting.sa,
    azurerm_monitor_diagnostic_setting.sa_sas,
    azurerm_monitor_diagnostic_setting.law,
    module.storage_account_subresources,
    module.storage_account_subresources_sas
  ]
}