resource "azurerm_monitor_diagnostic_setting" "aks_cluster_main" {
  for_each = {
    for key, value in module.aks : key => value.aks_cluster_name
  }
  name               = "ds-logs-${local.name_base}-aks"
  target_resource_id = module.aks[each.key].aks_cluster_id
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category = "kube-apiserver"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_cluster_agents_pool" {
  name               = "ds-logs-${local.name_base}-aks"
  target_resource_id = data.terraform_remote_state.enablers.outputs.aks_devops_id
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category = "kube-apiserver"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  for_each           = local.enablers_tfstate_output.nsg_ids
  name               = "ds-logs-${local.name_base}-nsg"
  target_resource_id = each.value
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category_group = "allLogs"
  }
}

resource "azurerm_monitor_diagnostic_setting" "databricks_cluster" {
  name               = "ds-logs-${local.name_base}-dbw"
  target_resource_id = module.databricks.databricks_id
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category_group = "allLogs"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  for_each = {
    for key, value in module.keyvault : key => value.key_vault_name
  }
  name               = "ds-logs-${local.name_base}-kv"
  target_resource_id = module.keyvault[each.key].key_vault_id
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "law" {
  name               = "ds-logs-${local.name_base}-law"
  target_resource_id = local.storage_account.diagnostic_set_id
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sa_law" {
  name                       = "${local.storage_account.diagnostic_set_name}-law"
  target_resource_id         = "${module.storage_account["law"].id}/blobServices/default/"
  log_analytics_workspace_id = local.storage_account.diagnostic_set_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }
}

resource "azurerm_monitor_diagnostic_setting" "sa" {
  for_each = {
    for key, value in local.storage_account.objects : key => value if key != "law" && value["shared_access_key_enabled"] == false
  }
  name               = local.storage_account.diagnostic_set_name
  target_resource_id = "${module.storage_account[each.key].id}/blobServices/default/"
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  # TODO: Review what metrics we need and enable them if needed.
  metric {
    category = "Capacity"
    enabled  = false
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sa_sas" {
  for_each = {
    for key, value in local.storage_account.objects : key => value if key != "law" && value["shared_access_key_enabled"] == true
  }
  name               = local.storage_account.diagnostic_set_name
  target_resource_id = "${module.storage_account_sas[each.key].id}/blobServices/default/"
  storage_account_id = module.storage_account["law"].id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  # TODO: Review what metrics we need and enable them if needed.
  metric {
    category = "Capacity"
    enabled  = false
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

# # Create a storage management policy to define log retention
# resource "azurerm_storage_management_policy" "sa" {
#   storage_account_id = azurerm_storage_account.sa.id

#   rule {
#     name    = "retention-policy"
#     enabled = true
#     filters {
#       prefix_match = ["logs/"]
#       blob_types   = ["blockBlob"]
#     }
#     actions {
#       base_blob {
#         tier_to_cool_after_days_since_modification_greater_than    = 3
#         tier_to_archive_after_days_since_modification_greater_than = 9
#         delete_after_days_since_modification_greater_than          = 10
#       }
#     }
#   }
# }
