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
  description = "Azure Container Registry name"
}

variable "tags" {
  type        = map(string)
  description = "Tags assign to created resources"
}

variable "sku" {
  type        = string
  description = "The SKU name of the the container registry. Possible values are Basic, Standard and Premium."

  validation {
    error_message = "Only 'Basic', 'Standard' and 'Premium' values are allowed"
    condition = contains([
      "Basic",
      "Standard",
      "Premium"
    ], var.sku)
  }
}

variable "admin_enabled" {
  type        = bool
  description = "Specifies whether the admin user is enabled."
  default     = false
}

variable "georeplication_enabled" {
  type        = bool
  description = "Specifies whether the admin user is enabled."
  default     = false
}

variable "georeplication_locations" {
  type = set(object({
    location                  = string,
    regional_endpoint_enabled = bool,
    zone_redundancy_enabled   = bool
  }))
  description = <<DESC
  A set of Azure locations where the container registry should be geo-replicated. Only activated on Premium SKU.
  Supported properties are:
    location                  = string
    zone_redundancy_enabled   = bool
    regional_endpoint_enabled = bool
    tags                      = map(string)
  or this can be a list of `string` (each element is a location)
  DESC
  default     = []
}

variable "retention_policy_enabled" {
  description = "Specifies whether images retention is enabled - if True, SKU must be Premium."
  type        = bool
  default     = false
}

variable "retention_policy_days" {
  type        = number
  description = "Specifies the number of images retention days."
  default     = 7
}

variable "azure_services_bypass_allowed" {
  type        = bool
  description = "Whether to allow trusted Azure services to access a network restricted Container Registry"
  default     = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is allowed for the container registry - if False, SKU must be Premium"
  default     = true
}

variable "trust_policy_enabled" {
  type        = bool
  description = "Specifies whether the trust policy is enabled - if True, SKU must be Premium"
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Specifies whether to enable dedicated data endpoints for this Container Registry - if True, SKU must be Premium."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Specifies whether zone redundancy is enabled - if True, SKU must be Premium."
  type        = bool
  default     = false
}

variable "allowed_cidrs" {
  type        = set(string)
  description = "List of CIDRs to allow on the registry"
  default     = []
}

variable "allowed_subnets" {
  type        = set(string)
  description = "List of VNet/Subnet IDs to allow on the registry"
  default     = []
}

variable "diagnostic_law_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostic setting"
}