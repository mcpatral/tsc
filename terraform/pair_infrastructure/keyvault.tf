resource "azurerm_key_vault_access_policy" "kv_policy" {
  for_each                = { for item in local.key_vault_access_policy : item.resource_key => item }
  key_vault_id            = local.infrastructure_tfstate_output.key_vault_id[each.value.key_vault_key]
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = each.value.object_id
  certificate_permissions = try(each.value.certificate_permissions, null)
  key_permissions         = try(each.value.key_permissions, null)
  secret_permissions      = try(each.value.secret_permissions, null)
  storage_permissions     = try(each.value.storage_permissions, null)
}

resource "azurerm_key_vault_key" "keys" {
  for_each     = local.key_vault_key.objects
  name         = each.value.key_name
  tags         = merge(local.common_tags, try(local.keyvault.objects["${each.value.kv_key}"].tags,{}))
  key_vault_id = local.infrastructure_tfstate_output.key_vault_id["${each.value.kv_key}"]
  key_type     = local.key_vault_key.key_type
  key_size     = local.key_vault_key.key_size
  key_opts     = local.key_vault_key.key_opts
  #rotation_policy {} #TODO review if an automatic periodic rotation policy is necessary
  depends_on = [
    time_sleep.wait_for_dns_a_records
  ]
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each     = local.key_vault_secret
  name         = each.value.secret_name
  tags         = merge(local.common_tags, try(local.keyvault.objects["${each.value.kv_key}"].tags,{}))
  value        = each.value.secret_value
  key_vault_id = local.infrastructure_tfstate_output.key_vault_id["${each.value.kv_key}"]
  depends_on = [
    time_sleep.wait_for_dns_a_records,
    time_sleep.wait_for_sa_dns_a_records
  ]
}