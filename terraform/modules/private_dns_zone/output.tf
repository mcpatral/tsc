output "dns_zone" {
  value = azurerm_private_dns_zone.dns_zone.name
}
output "dns_zone_id" {
  value = azurerm_private_dns_zone.dns_zone.id
}
output "dns_zone_link" {
  value = azurerm_private_dns_zone_virtual_network_link.dns_link.name
}