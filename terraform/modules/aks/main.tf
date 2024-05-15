resource "azurerm_kubernetes_cluster" "aks" {
  name                                = var.name
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  tags                                = var.tags
  kubernetes_version                  = var.kubernetes_version
  sku_tier                            = var.sku
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  dns_prefix                          = var.private_dns_zone_id != null ? null : var.dns_prefix
  dns_prefix_private_cluster          = var.private_dns_zone_id != null ? var.dns_prefix : null
  private_dns_zone_id                 = var.private_dns_zone_id != null ? var.private_dns_zone_id : null
  open_service_mesh_enabled           = var.open_service_mesh_enabled
  http_application_routing_enabled    = local.http_application_routing_enabled
  azure_policy_enabled                = local.azure_policy_enabled
  workload_identity_enabled           = var.workload_identity_enabled
  local_account_disabled              = local.local_account_disabled
  role_based_access_control_enabled   = local.role_based_access_control_enabled
  run_command_enabled                 = local.run_command_enabled
  oidc_issuer_enabled                 = var.oidc_issuer_enabled

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? [var.identity_id] : null
  }

  default_node_pool {
    name                        = var.default_node_pool["name"]
    vm_size                     = var.default_node_pool["vm_size"]
    node_count                  = var.default_node_pool["node_count"]
    vnet_subnet_id              = var.default_node_pool["subnet_id"]
    orchestrator_version        = var.default_node_pool["orchestrator_version"]
    min_count                   = try(var.default_node_pool["node_min_count"], null)
    max_count                   = try(var.default_node_pool["node_max_count"], null)
    max_pods                    = try(var.default_node_pool["node_max_pods"], null)
    enable_auto_scaling         = var.default_node_pool["auto_scaling_enabled"]
    enable_node_public_ip       = local.cluster_node_pools_public_ip_enabled
    enable_host_encryption      = local.enable_host_encryption
    temporary_name_for_rotation = local.temporary_name_for_rotation
    upgrade_settings {
      max_surge = local.upgrade_settings_max_surge
    }
  }

  dynamic "auto_scaler_profile" {
    for_each = var.default_node_pool["auto_scaling_enabled"] && var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []

    content {
      balance_similar_node_groups      = auto_scaler_profile.value["balance_similar_node_groups"]
      max_graceful_termination_sec     = auto_scaler_profile.value["max_graceful_termination_sec"]
      scan_interval                    = auto_scaler_profile.value["scan_interval"]
      scale_down_delay_after_add       = auto_scaler_profile.value["scale_down_delay_after_add"]
      scale_down_delay_after_delete    = auto_scaler_profile.value["scale_down_delay_after_delete"]
      scale_down_delay_after_failure   = auto_scaler_profile.value["scale_down_delay_after_failure"]
      scale_down_unneeded              = auto_scaler_profile.value["scale_down_unneeded"]
      scale_down_unready               = auto_scaler_profile.value["scale_down_unready"]
      scale_down_utilization_threshold = auto_scaler_profile.value["scale_down_utilization_threshold"]
    }
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = tls_private_key.ssh.public_key_openssh
    }
  }

  monitor_metrics {
    annotations_allowed = var.metric_annotations_allowlist
    labels_allowed      = var.metric_labels_allowlist
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = var.network_lb_sku
    outbound_type     = var.network_outbound_type
    pod_cidr          = local.network_pod_cidr
  }

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [var.api_server_authorized_ips]
    content {
      authorized_ip_ranges = api_server_access_profile.value
    }
  }

  # TODO: KV provider configuration needs to be done in the future
  # key_vault_secrets_provider {
  #   secret_identity {
  #     client_id                 = ""
  #     object_id                 = ""
  #     user_assigned_identity_id = ""
  #   }
  # }

  maintenance_window {
    allowed {
      day   = var.maintenance_window_allowed_day
      hours = var.maintenance_window_allowed_hours
    }
  }
  dynamic "microsoft_defender" {
    for_each = var.oms_agent_enabled ? [var.oms_agent_enabled] : []
    content {
      log_analytics_workspace_id = var.diagnostic_law_id
    }
  }

  storage_profile {
    blob_driver_enabled = var.csi_blob_driver_enabled
    file_driver_enabled = var.csi_file_driver_enabled
    disk_driver_enabled = var.csi_disk_driver_enabled
    disk_driver_version = local.csi_disk_driver_version
  }
  dynamic "oms_agent" {
    for_each = var.oms_agent_enabled ? [var.oms_agent_enabled] : []
    content {
      msi_auth_for_monitoring_enabled = oms_agent.value
      log_analytics_workspace_id      = var.diagnostic_law_id
    }
  }
  lifecycle {
    ignore_changes = [
      tags["aksContainerImageVersion"],
      default_node_pool.0.node_count
    ]
  }
}
