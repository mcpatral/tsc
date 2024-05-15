variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region to use"
}

variable "name" {
  type        = string
  description = "Azure Kuberneters cluster name"
}

variable "tags" {
  type        = map(string)
  description = "Tags assign to created resources"
}

variable "sku" {
  type        = string
  description = "The SKU name of the the AKS cluster. Possible values are Free and Standard."

  validation {
    error_message = "Only 'Free' and 'Standard' values are allowed"
    condition = contains([
      "Free",
      "Standard"
    ], var.sku)
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes Version for AKS cluster"
}

variable "open_service_mesh_enabled" {
  type        = bool
  default     = false
  description = "Enable Open Service Mesh in cluster"
}

variable "oms_agent_enabled" {
  type        = bool
  default     = false
  description = "Enable OMS agent"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix specified when creating the managed cluster."
}

variable "admin_username" {
  type        = string
  default     = "k8s_admin"
  description = "Kubernetes cluster's Admin username"
}

variable "private_cluster_enabled" {
  type        = bool
  default     = false
  description = "Enable private cluster configuration"
}

variable "private_cluster_public_fqdn_enabled" {
  type        = bool
  default     = false
  description = "Enable public FQDN generation for Private Cluster setup"
}

variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = <<EOF
  (Optional) Either the ID of Private DNS Zone which should be delegated to this Cluster, 
  System to have AKS manage this or None. In case of None you will need to bring your own DNS server 
  and set up resolving, otherwise, the cluster will have issues after provisioning. 
  Changing this forces a new resource to be created."
  EOF
}

variable "identity_type" {
  type        = string
  default     = "SystemAssigned"
  description = "(Optional) Specifies a type of Managed Identity of Kubernetes Cluster."
}

variable "identity_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies User Assigned Managed Identity ID to be assigned to this Kubernetes Cluster."
}

variable "api_server_authorized_ips" {
  type        = set(string)
  default     = []
  description = "Set of IPs/CIDR blocks that allowed to connect to API server of cluster - can't have more than 200 entries"

  validation {
    error_message = "Entries number should be below or equal to 200"
    condition     = length(var.api_server_authorized_ips) <= 200
  }
}

variable "maintenance_window_allowed_day" {
  type        = string
  default     = "Monday"
  description = "Allowed day for AKS cluster maintenance - only one day can be specified"
}

variable "maintenance_window_allowed_hours" {
  type        = list(number)
  default     = [3, 4]
  description = "Allowed hours for AKS cluster maintenance - list of hours allowed for maintenance"
}

variable "network_plugin" {
  type        = string
  default     = "azure"
  description = "Network plugin to use for AKS cluster - Only 'azure', 'kubenet' and 'none' values are allowed"

  validation {
    error_message = "Only 'azure', 'kubenet' and 'none' values are allowed"
    condition = contains([
      "azure",
      "kubenet",
      "none"
    ], var.network_plugin)
  }
}

variable "network_policy" {
  type        = string
  default     = "azure"
  description = "Network policy to use for AKS cluster - Only 'azure' and 'calico' values are allowed"

  validation {
    error_message = "Only 'azure' and 'calico' values are allowed"
    condition = contains([
      "azure",
      "calico"
    ], var.network_policy)
  }
}

variable "network_lb_sku" {
  type        = string
  default     = "standard"
  description = "Network Load Balancer SKU - Only 'basic' and 'standard' values are allowed"

  validation {
    error_message = "Only 'basic' and 'standard' values are allowed"
    condition = contains([
      "basic",
      "standard"
    ], var.network_lb_sku)
  }
}

variable "network_outbound_type" {
  type        = string
  default     = "loadBalancer"
  description = "(Optional) The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer and userDefinedRouting. Defaults to loadBalancer."
}

variable "network_pod_cidr" {
  type        = string
  default     = null
  description = "Pods internal CIDR for Kubernetes cluster. Will be set to 'null' if 'var.network_plugin' == 'azure'"
}

variable "vnet_id" {
  type        = string
  description = "VNet ID to authorize AKS working with"
}

variable "acr_id" {
  type        = string
  description = "ACR ID to authorize AKS working with"
}

variable "diagnostic_law_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostic setting"
}

variable "default_node_pool" {
  type = object({
    name                 = optional(string, "defaultpool")
    vm_size              = string,
    node_count           = number,
    subnet_id            = string,
    orchestrator_version = string,
    auto_scaling_enabled = bool,
    node_min_count       = optional(number, null),
    node_max_count       = optional(number, null),
    node_max_pods        = optional(number, 20)
  })
  description = <<DESC
  Default node pool configuration object structure
  Supported properties are:
    name                 = string - name of the default pool
    vm_size              = string - Standard VM size for pool, refer to Azure documentation for possible values
    node_count           = number - Node number to create in pool
    subnet_id            = string - ID of subnet where to deploy nodes
    orchestrator_version = string - Kubernetes version to use on node pool
    auto_scaling_enabled = bool - enables auto scaling for pool,
    node_min_count       = optional(number) - required if auto scaling is enabled, min number of nodes in pool
    node_max_count       = optional(number) - required if auto scaling is enabled, max number of nodes in pool
    node_max_pods        = optional(number) - required if auto scaling is enabled, max pods on node in pool
  DESC
}

variable "cluster_node_pools" {
  type = map(object({
    vm_size              = string,
    node_count           = number,
    subnet_id            = string,
    orchestrator_version = string,
    mode                 = string,
    scale_down_mode      = string,
    auto_scaling_enabled = bool,
    node_min_count       = optional(number, null),
    node_max_count       = optional(number, null),
    node_max_pods        = optional(number, 20),
    node_labels          = optional(map(string), { pool = "application" })
    os_disk_size_gb      = optional(number, null),
    os_disk_type         = optional(string, null),
    os_sku               = optional(string, "Ubuntu"),
    os_type              = optional(string, "Linux")
  }))
  default     = {}
  description = <<DESC
  List of node pools objects - object structure
  Supported properties are:
    name                 = string - name of the default pool
    vm_size              = string - Standard VM size for pool, refer to Azure documentation for possible values
    node_count           = number - Node number to create in pool
    subnet_id            = string - ID of subnet where to deploy nodes
    orchestrator_version = string - Kubernetes version to use on node pool
    mode                 = string - Specify types of pods for agent pool. Possible values - "User", "System"
    auto_scaling_enabled = bool - enables auto scaling for pool,
    node_min_count       = optional(number) - required if auto scaling is enabled, min number of nodes in pool
    node_max_count       = optional(number) - required if auto scaling is enabled, max number of nodes in pool
    node_max_pods        = optional(number) - required if auto scaling is enabled, max pods on node in pool
    os_disk_size_gb      = optional(string) - OS Disk size in GB. If not specified, uses default Azure node size
    os_disk_type         = optional(string) - OS Disk type. If not specified, uses default Azure node type
    os_sku               = optional(string) - If not specified, used "Ubuntu". Possible values - "Ubuntu", "AzureLinux" if os_type = "Linux". Possible values - "Windows2019", "Windows2022" if os_type = "Windows".
    os_type              = optional(string) - If not specified, used "Linux". Possible values - "Linux", "Windows"
  DESC
}

variable "auto_scaler_profile" {
  type = object({
    balance_similar_node_groups      = bool,
    max_graceful_termination_sec     = number,
    scan_interval                    = number,
    scale_down_delay_after_add       = number,
    scale_down_delay_after_delete    = number,
    scale_down_delay_after_failure   = number,
    scale_down_unneeded              = number,
    scale_down_unready               = number,
    scale_down_utilization_threshold = number
  })
  default     = null
  description = <<DESC
  Auto Scaler Profile settings accepts:
    balance_similar_node_groups      = bool,
    max_graceful_termination_sec     = number,
    scan_interval                    = number,
    scale_down_delay_after_add       = number,
    scale_down_delay_after_delete    = number,
    scale_down_delay_after_failure   = number,
    scale_down_unneeded              = number,
    scale_down_unready               = number,
    scale_down_utilization_threshold = number
  DESC
}

variable "csi_blob_driver_enabled" {
  type        = bool
  default     = true
  description = "Enables CSI Blob driver in cluster"
}

variable "csi_file_driver_enabled" {
  type        = bool
  default     = true
  description = "Enables CSI File driver in cluster"
}

variable "csi_disk_driver_enabled" {
  type        = bool
  default     = true
  description = "Enables CSI Disk driver in cluster"
}

variable "oidc_issuer_enabled" {
  type        = bool
  default     = false
  description = "Enables oidc issuer (needed for workload identity)"
}

variable "workload_identity_enabled" {
  type        = bool
  default     = false
  description = "Enables Workload identities"
}

variable "metric_labels_allowlist" {
  type    = string
  default = null
}

variable "metric_annotations_allowlist" {
  type    = string
  default = null
}