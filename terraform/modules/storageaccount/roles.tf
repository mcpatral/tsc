resource "azurerm_role_assignment" "sa_role" {
  for_each                         = var.role_mappings
  principal_id                     = each.value.principal_id
  principal_type                   = each.value.principal_type
  role_definition_name             = each.value.role_definition_name
  scope                            = azurerm_storage_account.sa.id
  skip_service_principal_aad_check = each.value.principal_type == "ServicePrincipal" ? true : null
  depends_on = [
    azurerm_storage_account.sa
  ]
}