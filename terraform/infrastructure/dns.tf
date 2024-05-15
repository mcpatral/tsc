#Key vault resources need to be deployed and provisioned before storage account resources, 
#this is the reason for separating not SA DNS resources from SA DNS resources

########### NOT SA DNS RESOURCES
resource "azurerm_private_endpoint" "pe" {
  for_each = {
    for key, value in local.private_endpoint.objects :
    key => value if !startswith(key, "sa_")
  }
  name                = "pe-${each.value.resource_name}-${each.value.subresource_name}"
  location            = var.LOCATION
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  tags                = merge(local.common_tags, try(each.value.tags, {}))
  subnet_id           = local.private_endpoint.subnet_id
  private_service_connection {
    name                           = "psc-${each.value.resource_name}-${each.value.subresource_name}"
    private_connection_resource_id = try(each.value.resource_id, module.keyvault[each.value.resource_key].key_vault_id)
    subresource_names              = [each.value.subresource_name]
    is_manual_connection           = local.private_endpoint.is_manual_connection
  }
}

resource "azurerm_private_endpoint" "pe_dbw" {
  name                = "pe-${local.databricks.name_dbw}-databricks_ui_api"
  location            = var.LOCATION
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  tags                = merge(local.common_tags, local.databricks.tags)
  subnet_id           = local.private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${local.databricks.name_dbw}-databricks_ui_api"
    private_connection_resource_id = module.databricks.databricks_id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = local.private_endpoint.is_manual_connection
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-${local.databricks.name_dbw}"
    private_dns_zone_ids = [local.enablers_tfstate_output.managed_private_dns_zone_id["azuredatabricks"]]
  }
}

resource "azurerm_private_dns_a_record" "pe" {
  for_each = {
    for key, value in local.private_dns_a_record.objects :
    key => value if !startswith(key, "sa_")
  }
  name                = each.value.name
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  zone_name           = local.enablers_tfstate_output.managed_private_dns_zone_name[each.value.zone_key]
  records             = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record.ttl_seconds
}

resource "azurerm_private_dns_a_record" "pe_hub" {
  for_each = {
    for key, value in local.private_dns_a_record_hub.objects :
    key => value if !startswith(key, "sa_")
  }
  provider            = azurerm.hub
  name                = each.value.name
  resource_group_name = local.enablers_tfstate_output.hub_private_dns_zone_resource_group_name
  zone_name           = local.enablers_tfstate_output.hub_private_dns_zone_name[each.value.zone_key]
  records             = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record_hub.ttl_seconds
}

resource "azurerm_private_dns_a_record" "pe_dbw_hub" {
  provider            = azurerm.hub
  count               = var.VNET_PEERED ? 1 : 0
  name                = azurerm_private_endpoint.pe_dbw.private_dns_zone_configs[0].record_sets[0].name
  resource_group_name = local.enablers_tfstate_output.hub_private_dns_zone_resource_group_name
  zone_name           = local.enablers_tfstate_output.hub_private_dns_zone_name["azuredatabricks"]
  records             = azurerm_private_endpoint.pe_dbw.private_dns_zone_configs[0].record_sets[0].ip_addresses
  ttl                 = local.private_dns_a_record_hub.ttl_seconds
}

resource "time_sleep" "wait_for_dns_a_records_to_propagate" {
  create_duration = "45s"
  depends_on = [
    azurerm_private_dns_a_record.pe,
    azurerm_private_dns_a_record.pe_hub,
    azurerm_private_dns_a_record.pe_dbw_hub
  ]
}

########### SA DNS RESOURCES
resource "azurerm_private_endpoint" "pe_sa" {
  for_each = {
    for key, value in local.private_endpoint.objects :
    key => value if startswith(key, "sa_")
  }
  name                = "pe-${each.value.resource_name}-${each.value.subresource_name}"
  location            = var.LOCATION
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  tags                = merge(local.common_tags, try(each.value.tags, {}))
  subnet_id           = local.private_endpoint.subnet_id
  private_service_connection {
    name                           = "psc-${each.value.resource_name}-${each.value.subresource_name}"
    private_connection_resource_id = try(each.value.resource_id, module.storage_account[each.value.resource_key].id, module.storage_account_sas[each.value.resource_key].id)
    subresource_names              = [each.value.subresource_name]
    is_manual_connection           = local.private_endpoint.is_manual_connection
  }
}

resource "azurerm_private_dns_a_record" "pe_sa" {
  for_each = {
    for key, value in local.private_dns_a_record.objects :
    key => value if startswith(key, "sa_")
  }
  name                = each.value.name
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  zone_name           = local.enablers_tfstate_output.private_dns_zone_name[each.value.zone_key]
  records             = [for config in azurerm_private_endpoint.pe_sa[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record.ttl_seconds
}

resource "azurerm_private_dns_a_record" "pe_sa_hub" {
  for_each = {
    for key, value in local.private_dns_a_record_hub.objects :
    key => value if startswith(key, "sa_")
  }
  provider            = azurerm.hub
  name                = each.value.name
  resource_group_name = local.enablers_tfstate_output.hub_private_dns_zone_resource_group_name
  zone_name           = local.enablers_tfstate_output.hub_private_dns_zone_name[each.value.zone_key]
  records             = [for config in azurerm_private_endpoint.pe_sa[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record_hub.ttl_seconds
}

resource "time_sleep" "wait_for_sa_dns_a_records_to_propagate" {
  create_duration = "45s"
  depends_on = [
    azurerm_private_dns_a_record.pe_sa,
    azurerm_private_dns_a_record.pe_sa_hub
  ]
}