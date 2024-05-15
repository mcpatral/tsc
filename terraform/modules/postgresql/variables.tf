variable "rg_name" {
  type        = string
  description = "Resource group name"
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Set of tags to assign to created resources"
}
variable "location" {
  description = "The location of the postgresql flexible server."
  type        = string
  nullable    = false
}
variable "psql_name" {
  description = "Postgresql flexible server name"
  type        = string
  nullable    = false
}
variable "create_mode" {
  description = "Postgresql flexible server create mode"
  type        = string
  default     = null
}
variable "psql_admin_user" {
  description = "Postgresql flexible server user"
  type        = string
  nullable    = false
}
variable "psql_admin_pwd" {
  description = "Postgresql flexible server password"
  type        = string
  nullable    = false
  sensitive   = true
}
variable "psql_version" {
  description = "Postgresql flexible server version"
  type        = string
  nullable    = false
}
variable "geo_redundant_backup_enabled" {
  description = "Postgresql geo redundant backup enabled"
  type        = bool
  default     = false
}
variable "zone" {
  description = "Postgresql flexible server zone"
  type        = string
  nullable    = false
}
variable "storage_mb" {
  description = "The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, and 16777216."
  type        = string
  nullable    = false
}

variable "sku_name" {
  description = "The SKU Name for the PostgreSQL Flexible Server. The name of the SKU, follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)."
  type        = string
  nullable    = false
}
variable "database_name" {
  description = "Postgresql flexible server database name."
  type        = string
  nullable    = false
}
variable "collation" {
  description = "Postgresql flexible server database collation."
  type        = string
  nullable    = false
}
variable "charset" {
  description = "Postgresql flexible server database charset."
  type        = string
  nullable    = false
}
variable "delegated_subnet_id" {
  description = "Postgresql flexible server database delegated subnet id."
  type        = string
  nullable    = false
}
variable "private_dns_zone_id" {
  description = "Postgresql flexible server database private dns zone id."
  type        = string
  nullable    = false
}
variable "diagnostic_set_name" {
  description = "Postgresql flexible server diagnostic setting name."
  type        = string
  nullable    = false
}
variable "diagnostic_set_id" {
  description = "Postgresql flexible server diagnostic setting id."
  type        = string
  nullable    = false
}
variable "principal_name" {
  description = "AAD admin name"
  type        = string
  nullable    = false
}
variable "object_id" {
  description = "AAD object id"
  type        = string
  nullable    = false
}
variable "tenant_id" {
  description = "AAD tenant id"
  type        = string
  nullable    = false
}
variable "high_availability_same_zone" {
  description = "High availability same zone"
  type        = bool
  default     = false
}
variable "high_availability_zone" {
  description = "High availability zone"
  type        = string
  default     = null
}
variable "point_in_time_restore_time_in_utc" {
  description = "The point in time to restore from source_server_id when create_mode is PointInTimeRestore."
  type        = string
  default     = null
}

variable "source_server_id" {
  description = "Source server id when create_mode is PointInTimeRestore or Replica."
  type        = string
  default     = null
}

variable "max_connections" {
  description = "Maximum active connections to the PostgreSQL server"
  type        = number
  default     = 50
}
