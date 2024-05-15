resource "azurerm_route_table" "rt" {
  name                = "rt-${local.name_base}"
  location            = var.PAIR_LOCATION
  resource_group_name = azurerm_resource_group.rg.name
  tags                = merge(local.common_tags, {/*include tags here*/})
}

module "nsg" {
  source                  = "../modules/nsg"
  for_each                = toset(values(local.subnet_key_names))
  name                    = "nsg-${local.name_base}-${each.key}"
  location                = var.PAIR_LOCATION
  resource_group_name     = azurerm_resource_group.rg.name
  tags                    = merge(local.common_tags, {/*include tags here*/})
  inbound_security_rules  = try(local.inbound_security_rules[each.key], {})
  outbound_security_rules = try(local.outbound_security_rules[each.key], {})
}

module "vnet" {
  source                                                = "../modules/networks"
  vnet_name                                             = "vnet-${local.name_base}"
  vnet_location                                         = var.PAIR_LOCATION
  resource_group_name                                   = azurerm_resource_group.rg.name
  tags                                                  = merge(local.common_tags, try(local.vnet.tags,{}))
  address_space                                         = local.vnet.cidr_blocks
  subnets                                               = local.vnet.subnets
  route_tables_ids                                      = local.vnet.route_tables_ids
  nsg_ids                                               = local.vnet.nsg_ids
  subnet_service_endpoints                              = local.vnet.subnet_service_endpoints
  subnet_delegation                                     = local.vnet.subnet_delegation
  subnet_enforce_private_link_endpoint_network_policies = local.vnet.subnet_enforce_private_link_endpoint_network_policies
}
