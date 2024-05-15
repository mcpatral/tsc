locals {
  # TODO: Review settings separately and discuss these with IT/Security team
  http_application_routing_enabled     = false
  azure_policy_enabled                 = true
  local_account_disabled               = false
  role_based_access_control_enabled    = true
  run_command_enabled                  = true
  cluster_node_pools_public_ip_enabled = false
  cluster_node_pools_priority          = "Regular"
  csi_disk_driver_version              = "v1"
  network_pod_cidr                     = var.network_plugin != "azure" ? var.network_pod_cidr : null
  temporary_name_for_rotation          = "tempnode"
  enable_host_encryption               = true
  upgrade_settings_max_surge           = "10%"

  enabled_logs = {
    "kube-apiserver"          = false,
    "kube-audit"              = false,
    "kube-audit-admin"        = true,
    "kube-controller-manager" = false,
    "kube-scheduler"          = false,
    "cluster-autoscaler"      = false,
    "guard"                   = false
  }
}
