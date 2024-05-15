#Key vault resources need to be deployed and provisioned before storage account resources, 
#this is the reason for separating not SA DNS resources from SA DNS resources

########### NOT SA DNS RESOURCES
resource "azurerm_private_endpoint" "pe" {
  for_each = {
    for key, value in local.private_endpoint.objects :
    key => value if !startswith(key, "sa_")
  }
  name                = "pe-${each.value.resource_name}-${each.value.subresource_name}"
  location            = var.PAIR_LOCATION
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  tags                = merge(local.common_tags, try(each.value.tags,{}))
  subnet_id           = local.private_endpoint.subnet_id
  private_service_connection {
    name                           = "psc-${each.value.resource_name}-${each.value.subresource_name}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource_name]
    is_manual_connection           = local.private_endpoint.is_manual_connection
  }
}

resource "azurerm_private_dns_a_record" "pe" {
  for_each = {
    for key, value in local.private_dns_a_record.objects :
    key => value if !startswith(key, "sa_")
  }
  name                = each.value.name
  resource_group_name = local.enablers_tfstate_output.resource_group_name_primary
  zone_name           = local.enablers_tfstate_output.private_dns_zone_name[each.value.zone_key]
  records             = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record.ttl_seconds
}

resource "null_resource" "modify_a_records" {
  for_each = {
    for key, value in local.private_dns_a_record_null_resource.objects :
    key => value if !startswith(key, "sa_")
  }
  triggers = {
    name                = each.value.name
    resource_group_name = local.enablers_tfstate_output.resource_group_name_primary
    zone_name           = local.enablers_tfstate_output.private_dns_zone_name[each.value.zone_key]
    record              = [for config in azurerm_private_endpoint.pe[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0][0]
    ttl                 = local.private_dns_a_record.ttl_seconds
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

resource "time_sleep" "wait_for_dns_a_records" {
  create_duration = "45s"
  depends_on = [
    azurerm_private_dns_a_record.pe,
    null_resource.modify_a_records,
    azurerm_key_vault_access_policy.kv_policy
  ]
}

########### SA DNS RESOURCES
resource "azurerm_private_endpoint" "pe_sa" {
  for_each = {
    for key, value in local.private_endpoint.objects :
    key => value if startswith(key, "sa_")
  }
  name                = "pe-${each.value.resource_name}-${each.value.subresource_name}"
  location            = var.PAIR_LOCATION
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  tags                = merge(local.common_tags, try(each.value.tags,{}))
  subnet_id           = local.private_endpoint.subnet_id
  private_service_connection {
    name                           = "psc-${each.value.resource_name}-${each.value.subresource_name}"
    private_connection_resource_id = try(each.value.resource_id, module.storage_account[each.value.resource_key].id, module.storage_account_sas[each.value.resource_key].id)
    subresource_names              = [each.value.subresource_name]
    is_manual_connection           = local.private_endpoint.is_manual_connection
  }
  depends_on = [
    null_resource.sa_lock_create
  ]
}

resource "azurerm_private_dns_a_record" "pe_sa" {
  for_each = {
    for key, value in local.private_dns_a_record.objects :
    key => value if startswith(key, "sa_")
  }
  name                = each.value.name
  resource_group_name = local.enablers_tfstate_output.resource_group_name_primary
  zone_name           = local.enablers_tfstate_output.private_dns_zone_name[each.value.zone_key]
  records             = [for config in azurerm_private_endpoint.pe_sa[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0]
  ttl                 = local.private_dns_a_record.ttl_seconds
}

resource "null_resource" "modify_a_records_sa" {
  for_each = {
    for key, value in local.private_dns_a_record_null_resource.objects :
    key => value if startswith(key, "sa_")
  }
  triggers = {
    name                = each.value.name
    resource_group_name = local.enablers_tfstate_output.resource_group_name_primary
    zone_name           = local.enablers_tfstate_output.private_dns_zone_name[each.value.zone_key]
    record              = [for config in azurerm_private_endpoint.pe_sa[each.value.private_endpoint_key].custom_dns_configs : config.ip_addresses if strcontains(config.fqdn, "${each.value.name}.${each.value.zone_key}")][0][0]
    ttl                 = local.private_dns_a_record.ttl_seconds
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

resource "time_sleep" "wait_for_sa_dns_a_records" {
  create_duration = "45s"
  depends_on = [
    azurerm_private_dns_a_record.pe_sa,
    null_resource.modify_a_records_sa
  ]
}