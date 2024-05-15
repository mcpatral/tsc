variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_group_id" {
  type        = string
  description = "ID of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region to use"
}

variable "amw_name" {
  type        = string
  description = "Azure monitor workspace name"
}

variable "grafana_name" {
  type        = string
  description = "Azure grafana name"
}

variable "grafana_admin_group_ids" {
  type        = set(string)
  default     = []
  description = "Azure managed Grafana admin group ids"
}

variable "grafana_editor_group_ids" {
  type        = set(string)
  default     = []
  description = "Azure managed Grafana editor group ids"
}

variable "grafana_viewer_group_ids" {
  type        = set(string)
  default     = []
  description = "Azure managed Grafana viewer group ids"
}

variable "grafana_api_key_enabled" {
  type        = bool
  description = "Grafana api key enabled"
}

variable "grafana_deterministic_outbound_ip_enabled" {
  type        = bool
  description = "Grafana deterministic outbound ip enabled"
}

variable "grafana_public_network_access_enabled" {
  type        = bool
  description = "Grafana public network access enabled"
}

variable "aks_cluster_name" {
  type        = string
  description = "Main aks cluster name"
}

variable "aks_cluster_id" {
  type        = string
  description = "Main aks cluster id"
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}
