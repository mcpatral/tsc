resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_base}"
  location = var.LOCATION
  tags     = merge(local.common_tags, local.resource_group_tags)
}