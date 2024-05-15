resource "azurerm_private_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = var.rg_name
  tags                = var.tags
}


resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = var.dns_link_name
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}