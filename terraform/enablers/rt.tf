resource "azurerm_route_table" "rt" {
  for_each                      = local.subnet_route_tables.objects
  name                          = "rt-${local.name_base}-${each.value.name}"
  location                      = var.LOCATION
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = local.subnet_route_tables.disable_route_propagation
  tags                          = merge(local.common_tags, each.value.tags)
}

resource "azurerm_route" "route" {
  for_each               = local.subnet_routes
  name                   = each.value.name
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = each.value.route_table_name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}
