variable "kv_name" {
  type        = string
  description = "Key vault name"
  nullable    = false
}

variable "rg_name" {
  type        = string
  description = "Resource group name"
  nullable    = false
}

variable "location" {
  type        = string
  description = "Location where key vault will be created"
  nullable    = false
}

variable "subnets_id" {
  type        = list(string)
  description = "List of subnets that will have access to key vault"
}

variable "public_ip" {
  type        = list(string)
  description = "Ip list that will have access to key vault"
}

variable "sku" {
  type        = string
  default     = "standard"
  description = "Key vault tier"
}

variable "access_policy" {
  type = list(object({
    resource_key            = string
    object_id               = string
    application_id          = string #not used, bug in provider
    key_permissions         = optional(list(string))
    secret_permissions      = optional(list(string)),
    certificate_permissions = optional(list(string))
    storage_permissions     = optional(list(string))
  }))
  description = "Acess policies to set"
  nullable    = false

}

variable "purge_protection" {
  type        = bool
  description = "Should purge protection be enabled?"
  nullable    = false
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public assess?"
  default     = true
}

variable "tenant_id" {
  type        = string
  description = "Which tenant is used for KV (can be taken from env variables)"
  nullable    = false
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}

variable "diagnostic_set_name" {
  type        = string
  description = "Diagnostic setting name."
  nullable    = false
}

variable "diagnostic_set_id" {
  description = "Diagnostic setting id."
  type        = string
  nullable    = false
}

variable "soft_delete_retention_days" {
  description = "How much time we have to restore deletion"
  type        = number
  default     = 30
}
