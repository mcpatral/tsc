## Network security group
resource "azurerm_network_security_group" "nsg" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Inbound resources
resource "azurerm_network_security_rule" "inbound" {
  for_each                    = var.inbound_security_rules
  name                        = each.key
  priority                    = each.value["priority"]
  direction                   = "Inbound"
  access                      = each.value["access"]
  protocol                    = each.value["protocol"]
  source_port_range           = "*"
  destination_port_range      = each.value["port"]
  source_address_prefix       = each.value["src_address_prefix"]
  destination_address_prefix  = each.value["dst_address_prefix"]
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Outbound resources
resource "azurerm_network_security_rule" "outbound" {
  for_each                    = var.outbound_security_rules
  name                        = each.key
  priority                    = each.value["priority"]
  direction                   = "Outbound"
  access                      = each.value["access"]
  protocol                    = each.value["protocol"]
  source_port_range           = "*"
  destination_port_range      = each.value["port"]
  source_address_prefix       = each.value["src_address_prefix"]
  destination_address_prefix  = each.value["dst_address_prefix"]
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}