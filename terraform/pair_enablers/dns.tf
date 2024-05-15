resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  for_each              = local.private_dns_zone.objects
  name                  = local.private_dns_zone.link_name
  resource_group_name   = local.enablers_tfstate_output.resource_group_name
  tags                  = merge(local.common_tags, each.value.tags)
  private_dns_zone_name = each.value.name
  virtual_network_id    = module.vnet.vnet_id
}

resource "azurerm_private_endpoint" "pe" {
  for_each            = local.private_endpoint.objects
  name                = "pe-${each.value.resource_name}-${each.value.subresource_name}"
  location            = var.PAIR_LOCATION
  resource_group_name = azurerm_resource_group.rg.name
  tags                = merge(local.common_tags, try(each.value.tags,{}))
  subnet_id           = local.private_endpoint.subnet_id
  private_service_connection {
    name                           = "psc-${each.value.resource_name}-${each.value.subresource_name}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource_name]
    is_manual_connection           = local.private_endpoint.is_manual_connection
  }
  depends_on = [
    azurerm_monitor_private_link_scoped_service.pls_law,
    azurerm_monitor_private_link_scoped_service.pls_dce
  ]
}

resource "azurerm_private_dns_a_record" "pe" {
  for_each            = local.private_dns_a_record.objects
  name                = each.value.name
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  zone_name           = local.enablers_tfstate_output.private_dns_zone_name[each.value.zone_key]
  records             = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record.ttl_seconds
}

resource "null_resource" "delete_create_a_records" {
  for_each = local.private_dns_a_record_script.objects
  triggers = {
    name                = each.value.name
    resource_group_name = local.enablers_tfstate_output.resource_group_name
    zone_name           = local.enablers_tfstate_output.private_dns_zone_name[each.value.zone_key]
    record              = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0][0]
    ttl                 = local.private_dns_a_record_script.ttl_seconds
  }
  provisioner "local-exec" {
    when    = create
    command = <<EOT
az network private-dns record-set a delete -g ${self.triggers.resource_group_name} -z ${self.triggers.zone_name} -n ${self.triggers.name} --yes
az network private-dns record-set a create -g ${self.triggers.resource_group_name} -z ${self.triggers.zone_name} -n ${self.triggers.name} --ttl ${self.triggers.ttl}
az network private-dns record-set a add-record -g ${self.triggers.resource_group_name} -z ${self.triggers.zone_name} -n ${self.triggers.name} -a ${self.triggers.record}
EOT
  }
}