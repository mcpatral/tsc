#DNS private zones are resilient to regional outages because zone data is globally available. Resource records in a private zone are automatically replicated across regions.
#https://learn.microsoft.com/en-us/azure/dns/private-dns-resiliency
module "private_dns_zone" {
  source        = "../modules/private_dns_zone"
  for_each      = local.private_dns_zone.objects
  rg_name       = azurerm_resource_group.rg.name
  tags          = merge(local.common_tags, each.value.tags)
  dns_zone_name = each.value.name
  dns_link_name = local.private_dns_zone.link_name
  vnet_id       = module.vnet.vnet_id
}

resource "azurerm_private_endpoint" "pe" {
  for_each            = local.private_endpoint.objects
  name                = "pe-${each.value.resource_name}-${each.value.subresource_name}"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.rg.name
  tags                = merge(local.common_tags, try(each.value.tags, {}))
  subnet_id           = local.private_endpoint.subnet_id
  private_service_connection {
    name                           = "psc-${each.value.resource_name}-${each.value.subresource_name}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource_name]
    is_manual_connection           = local.private_endpoint.is_manual_connection
  }
  depends_on = [
    azurerm_monitor_private_link_scope.pls,
    azurerm_monitor_private_link_scoped_service.pls_law,
    azurerm_monitor_private_link_scoped_service.pls_dce
  ]
}

resource "azurerm_private_dns_a_record" "pe" {
  for_each            = local.private_dns_a_record.objects
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  zone_name           = module.private_dns_zone[each.value.zone_key].dns_zone
  records             = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record.ttl_seconds
}

resource "azurerm_private_dns_a_record" "pe_hub" {
  provider            = azurerm.hub
  for_each            = local.private_dns_a_record_hub.objects
  name                = each.value.name
  resource_group_name = var.HUB_DNS_RESOURCE_GROUP_NAME
  zone_name           = local.private_dns_zones_hub[each.value.zone_key].name
  records             = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record_hub.ttl_seconds
}
