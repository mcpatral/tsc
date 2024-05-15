#Disaster recovery notes:
#The contents of your key vault are replicated within the region and to a secondary region at least 150 miles away, 
#but within the same geography to maintain high durability of your keys and secrets. 
#In the rare event that an entire Azure region is unavailable, 
#the requests that you make of Azure Key Vault in that region are automatically routed (failed over) to a secondary region
#More info: https://learn.microsoft.com/en-us/azure/key-vault/general/disaster-recovery-guidance

#TODO to review access and network policy differences in future - this is why not via loop, they should differ much
module "keyvault" {
  source                        = "../modules/keyvault"
  for_each                      = local.keyvault.objects
  kv_name                       = "kv-${local.name_base}-${each.key}"
  rg_name                       = local.enablers_tfstate_output.resource_group_name
  location                      = var.LOCATION
  tags                          = merge(local.common_tags, each.value.tags)
  sku                           = local.keyvault.sku
  soft_delete_retention_days    = local.keyvault.soft_delete_retention_days
  purge_protection              = local.keyvault.purge_protection
  diagnostic_set_name           = local.keyvault.diagnostic_set_name
  diagnostic_set_id             = local.keyvault.diagnostic_set_id
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  subnets_id                    = each.value["subnets_id"]
  public_ip                     = each.value["public_ip"]
  access_policy                 = concat(local.keyvault.common_access_policies, each.value["access_policies"])
  public_network_access_enabled = each.value["kv_public_network_access_enabled"]
}

resource "azurerm_key_vault_key" "keys" {
  for_each     = local.key_vault_key.objects
  name         = each.value.key_name
  tags         = merge(local.common_tags, local.keyvault.objects[each.value.kv_key].tags)
  key_vault_id = module.keyvault["${each.value.kv_key}"].key_vault_id
  key_type     = local.key_vault_key.key_type
  key_size     = local.key_vault_key.key_size
  key_opts     = local.key_vault_key.key_opts
  #rotation_policy {} #TODO review if an automatic periodic rotation policy is necessary
  depends_on = [
    time_sleep.wait_for_dns_a_records_to_propagate
  ]
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each        = local.key_vault_secret
  name            = each.value.secret_name
  tags            = merge(local.common_tags, local.keyvault.objects[each.value.kv_key].tags)
  value           = each.value.secret_value
  key_vault_id    = module.keyvault["${each.value.kv_key}"].key_vault_id
  expiration_date = local.keyvault.expiration_date
  depends_on = [
    time_sleep.wait_for_dns_a_records_to_propagate,
    time_sleep.wait_for_sa_dns_a_records_to_propagate
  ]
}