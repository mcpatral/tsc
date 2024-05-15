output "vnet_address_space" {
  description = "The address space of the newly created vNet"
  value       = azurerm_virtual_network.vnet.address_space
}

output "vnet_id" {
  description = "The id of the newly created vNet"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_location" {
  description = "The location of the newly created vNet"
  value       = azurerm_virtual_network.vnet.location
}

output "vnet_name" {
  description = "The Name of the newly created vNet"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_subnets" {
  description = "The map of names and ids of subnets created inside the newly created vNet"
  value = {
    for subnet in azurerm_subnet.subnet : subnet.name => subnet.id
  }
}

output "vnet_nsg_id" {
  description = "Ths id of network security group created for Databricks"
  value       = var.nsg_ids
}