module "acr" {
  source                        = "../modules/acr"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = var.LOCATION
  tags                          = merge(local.common_tags, local.acr.tags)
  name                          = "acr${local.name_base_no_dash}${local.acr.name}"
  sku                           = var.ACR_SKU
  admin_enabled                 = local.acr.admin_enabled
  public_network_access_enabled = local.acr.public_network_access_enabled
  retention_policy_enabled      = local.acr.retention_policy_enabled
  retention_policy_days         = local.acr.retention_policy_days
  allowed_cidrs                 = local.acr.allowed_cidrs
  allowed_subnets               = local.acr.allowed_subnets
  zone_redundancy_enabled       = local.acr.zone_redundancy_enabled
  georeplication_enabled        = local.acr.georeplication_enabled
  georeplication_locations      = local.acr.georeplication_locations
  diagnostic_law_id             = var.CENTRAL_LAW_ID != null ? var.CENTRAL_LAW_ID : azurerm_log_analytics_workspace.law_main.0.id
  depends_on = [
    module.nsg,
    module.vnet
  ]
}

resource "azurerm_role_assignment" "role_spn_acr" {
  count                            = var.NEXT_ENV_SPN_OBJECT_ID != null ? 1 : 0
  principal_id                     = var.NEXT_ENV_SPN_OBJECT_ID
  role_definition_name             = "Reader"
  scope                            = module.acr.id
  skip_service_principal_aad_check = true
}
