resource "azurerm_databricks_access_connector" "connector" {
  for_each            = toset(local.connector_names)
  name                = each.value
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  location            = var.PAIR_LOCATION
  tags                = merge(local.common_tags, {/*include tags here*/})
  identity {
    type = "SystemAssigned"
  }
}