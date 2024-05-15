resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_base}"
  location = var.PAIR_LOCATION
  tags     = merge(local.common_tags, {/*include tags here*/})
}