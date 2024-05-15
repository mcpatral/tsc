resource "azurerm_key_vault" "kv" {
  name                          = var.kv_name
  location                      = var.location
  resource_group_name           = var.rg_name
  tenant_id                     = var.tenant_id
  sku_name                      = var.sku
  soft_delete_retention_days    = local.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled
  purge_protection_enabled      = var.purge_protection
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.public_ip
    virtual_network_subnet_ids = var.subnets_id
  }

  tags = var.tags
}

resource "azapi_update_resource" "acls" {
  type        = "Microsoft.KeyVault/vaults@2022-07-01"
  resource_id = azurerm_key_vault.kv.id

  body = jsonencode({
    properties = {
      networkAcls = {
        bypass        = "AzureServices"
        defaultAction = "Deny"
        ipRules = [
          for ip in var.public_ip : {
            value = ip
          }
        ]
        virtualNetworkRules = [
          for subnet in var.subnets_id : {
            id                               = lower(subnet)
            ignoreMissingVnetServiceEndpoint = true
          }
        ]
      }
    }
  })

  depends_on = [
    azurerm_key_vault.kv,
  ]
}

resource "azurerm_key_vault_access_policy" "kv_policy" {
  for_each                = { for item in var.access_policy : item.resource_key => item }
  key_vault_id            = azurerm_key_vault.kv.id
  tenant_id               = var.tenant_id
  object_id               = each.value.object_id
  certificate_permissions = try(each.value.certificate_permissions, null)
  key_permissions         = try(each.value.key_permissions, null)
  secret_permissions      = try(each.value.secret_permissions, null)
  storage_permissions     = try(each.value.storage_permissions, null)

  depends_on = [
    azapi_update_resource.acls,
  ]
}