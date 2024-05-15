resource "azurerm_container_registry" "registry" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = var.tags
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = local.public_network_access_enabled
  zone_redundancy_enabled       = local.zone_redundancy_enabled
  data_endpoint_enabled         = local.data_endpoint_enabled
  network_rule_bypass_option    = local.network_rule_bypass_option
  quarantine_policy_enabled     = local.quarantine_policy_enabled
  anonymous_pull_enabled        = local.anonymous_pull_enabled

  retention_policy {
    enabled = local.retention_policy_enabled
    days    = var.retention_policy_days
  }

  trust_policy {
    enabled = local.trust_policy_enabled
  }

  dynamic "georeplications" {
    for_each = local.georeplication_enabled ? var.georeplication_locations : []

    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                      = var.tags
    }
  }

  dynamic "network_rule_set" {
    for_each = local.network_rule_set_enabled ? local.network_rule_set : []

    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }

      dynamic "virtual_network" {
        for_each = network_rule_set.value.virtual_networks
        content {
          action    = "Allow"
          subnet_id = virtual_network.value
        }
      }
    }
  }
}