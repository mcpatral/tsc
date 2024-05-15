resource "azurerm_storage_account" "sa" {
  name                     = var.sa_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  access_tier              = var.access_tier
  tags                     = var.tags

  is_hns_enabled                    = var.is_hns_enabled
  large_file_share_enabled          = local.enable_large_file_share
  public_network_access_enabled     = var.public_network_access_enabled
  allow_nested_items_to_be_public   = local.allow_nested_items_to_be_public
  enable_https_traffic_only         = local.enable_https_traffic_only
  min_tls_version                   = local.min_tls_version
  nfsv3_enabled                     = var.nfsv3_enabled
  infrastructure_encryption_enabled = local.infrastructure_encryption_enabled
  shared_access_key_enabled         = var.shared_access_key_enabled
  default_to_oauth_authentication   = local.default_to_oauth_authentication
  #workaround for nfs 3
  network_rules {
    default_action             = var.default_network_rule
    ip_rules                   = var.authorized_ips
    virtual_network_subnet_ids = var.subnet_service_endpoints
    bypass                     = var.traffic_bypass

    dynamic "private_link_access" {
      for_each = contains(var.databricks_connector_assign_sa_list, var.sa_name) ? [1] : []
      content {
        endpoint_resource_id = var.databricks_access_connector_id
      }
    }
  }

  blob_properties {
    versioning_enabled = var.blob_versioning_enabled
    delete_retention_policy {
      days = var.delete_retention_days
    }
    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
    dynamic "cors_rule" {
      for_each = (var.blob_cors == null ? {} : var.blob_cors)
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
  }
  dynamic "customer_managed_key" {
    for_each = (var.key_vault_customer_managed_key_id != null ? [var.key_vault_customer_managed_key_id] : [])
    content {
      key_vault_key_id          = customer_managed_key.value
      user_assigned_identity_id = var.user_assigned_identity_id
    }
  }
  dynamic "identity" {
    for_each = (var.user_assigned_identity_id != null ? [var.user_assigned_identity_id] : [])
    content {
      type         = "UserAssigned"
      identity_ids = [identity.value]
    }
  }
}