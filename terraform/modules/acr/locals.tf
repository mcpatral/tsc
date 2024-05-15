locals {
  anonymous_pull_enabled        = false
  quarantine_policy_enabled     = false
  network_rule_bypass_option    = var.azure_services_bypass_allowed ? "AzureServices" : "None"
  premium_sku                   = var.sku == "Premium" ? true : false
  public_network_access_enabled = local.premium_sku ? var.public_network_access_enabled : true
  retention_policy_enabled      = local.premium_sku ? var.retention_policy_enabled : false
  trust_policy_enabled          = local.premium_sku ? var.trust_policy_enabled : false
  data_endpoint_enabled         = local.premium_sku ? var.data_endpoint_enabled : false
  zone_redundancy_enabled       = local.premium_sku ? var.zone_redundancy_enabled : false
  georeplication_enabled        = local.premium_sku ? var.georeplication_enabled : false
  network_rule_set_enabled      = local.premium_sku && (length(var.allowed_cidrs) > 0 || length(var.allowed_subnets) > 0) ? true : false
  network_rule_set = [
    {
      ip_rules         = var.allowed_cidrs,
      virtual_networks = var.allowed_subnets
    }
  ]
}