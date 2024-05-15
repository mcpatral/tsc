resource "azurerm_kubernetes_cluster_node_pool" "pool" {
  for_each               = var.cluster_node_pools
  name                   = each.key
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks.id
  vnet_subnet_id         = each.value.subnet_id
  vm_size                = each.value.vm_size
  orchestrator_version   = each.value.orchestrator_version
  enable_auto_scaling    = each.value.auto_scaling_enabled
  max_count              = each.value.node_max_count
  min_count              = each.value.node_min_count
  node_count             = each.value.node_count
  node_labels            = each.value.node_labels
  max_pods               = each.value.node_max_pods
  enable_host_encryption = local.enable_host_encryption
  enable_node_public_ip  = local.cluster_node_pools_public_ip_enabled
  priority               = local.cluster_node_pools_priority
  mode                   = each.value.mode
  scale_down_mode        = each.value.scale_down_mode
  os_disk_size_gb        = each.value.os_disk_size_gb
  os_disk_type           = each.value.os_disk_type
  os_sku                 = each.value.os_sku
  os_type                = each.value.os_type

  upgrade_settings {
    max_surge = local.upgrade_settings_max_surge
  }
}
