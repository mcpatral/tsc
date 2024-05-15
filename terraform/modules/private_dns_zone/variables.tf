variable "dns_zone_name" {
  type        = string
  description = "DNS Zone name"
}

variable "dns_link_name" {
  type        = string
  description = "DNS Zone link to VNet name"
}

variable "rg_name" {
  type        = string
  description = "Resource group name"
}

variable "vnet_id" {
  type        = string
  description = "VNet ID to link DNS zone with"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Set of tags to assign to created resources"
}
