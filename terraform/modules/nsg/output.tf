output "nsg_id" {
  description = "Id of the newly created Network security group"
  value       = azurerm_network_security_group.nsg.id
}

output "nsg_name" {
  description = "Name of the newly created Network security group"
  value       = azurerm_network_security_group.nsg.name
}
