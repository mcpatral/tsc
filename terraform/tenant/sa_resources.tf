module "storage_account_subresources" {
  source = "../modules/storageaccount_subresources"
  for_each = {
    for key, value in local.storage_account.objects :
    key => value
    if value["shared_access_key_enabled"] == false
  }
  storage_account_name = "sa${local.name_base_no_dash}${each.key}"
  storage_account_id   = data.azurerm_storage_account.sa[each.key].id
  nfsv3_enabled        = data.azurerm_storage_account.sa[each.key].nfsv3_enabled
  is_hns_enabled       = data.azurerm_storage_account.sa[each.key].is_hns_enabled
  containers           = each.value.containers
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
  storage_account_name = "sa${local.name_base_no_dash}${each.key}"
  storage_account_id   = data.azurerm_storage_account.sa[each.key].id
  nfsv3_enabled        = data.azurerm_storage_account.sa[each.key].nfsv3_enabled
  is_hns_enabled       = data.azurerm_storage_account.sa[each.key].is_hns_enabled
  containers           = each.value.containers
}