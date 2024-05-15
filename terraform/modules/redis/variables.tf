variable "redis_name" {
  description = "Redis cache name"
  type        = string
}
variable "rg_name" {
  description = "Resource group name where redis cache will be deployed"
  type        = string
}
variable "location" {
  description = "Azure location where redis will be deployed"
  type        = string
}
variable "tags" {
  description = "Tags for redis"
}
variable "capacity" {
  description = "Redis cache capacity"
  type        = number
}
variable "family" {
  description = "Redis family"
  type        = string
}
variable "sku_name" {
  description = "SKU of redis Basic/Standrd/Premium"
  type        = string
}
variable "enable_non_ssl_port" {
  description = "Redis cache access via SSL"
  type        = bool
}

variable "redis_version" {
  description = "Redis vesrion to use"
  type        = string
}
#Diagnostic Settings
variable "diagnostic_set_name" {
  description = "Log analytics workspace name"
  type        = string
}
variable "diagnostic_set_id" {
  description = "Log analytics workspace resource ID"
  type        = string
}