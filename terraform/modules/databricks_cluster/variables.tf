variable "name_dbw_cluster" {
  description = "(Optional) Cluster name, which doesn’t have to be unique. If not specified at creation, the cluster name will be an empty string."
  type        = string
  nullable    = false
}
variable "node_type_id" {
  description = "(Required - optional if instance_pool_id is given) Any supported databricks_node_type id. If instance_pool_id is specified, this field is not needed."
  type        = string
  nullable    = false
}
variable "driver_node_type_id" {
  description = "(Required - optional if instance_pool_id is given) Any supported databricks_node_type id. If instance_pool_id is specified, this field is not needed."
  type        = string
  nullable    = false
}
variable "autotermination_minutes" {
  description = "(Optional) Automatically terminate the cluster after being inactive for this time in minutes. If specified, the threshold must be between 10 and 10000 minutes. You can also set this value to 0 to explicitly disable automatic termination. Defaults to 60. We highly recommend having this setting present for Interactive/BI clusters."
  type        = string
  nullable    = false
}
variable "data_security_mode" {
  description = "(Optional) Select the security features of the cluster. Unity Catalog requires SINGLE_USER or USER_ISOLATION mode. LEGACY_PASSTHROUGH for passthrough cluster and LEGACY_TABLE_ACL for Table ACL cluster. Default to NONE, i.e. no security feature enabled. In the Databricks UI, this has been recently been renamed Access Mode and USER_ISOLATION has been renamed Shared, but use these terms here."
  type        = string
  nullable    = false
}
variable "min_workers" {
  description = "(Optional) The minimum number of workers to which the cluster can scale down when underutilized. It is also the initial number of workers the cluster will have after creation."
  type        = string
  nullable    = false
}
variable "max_workers" {
  description = "(Optional) The maximum number of workers to which the cluster can scale up when overloaded. max_workers must be strictly greater than min_workers."
  type        = string
  nullable    = false
}
variable "spark_databricks_io_cache_enabled" {
  description = "spark_databricks_io_cache_enabled from spark_conf"
  type        = string
  nullable    = false
}
variable "spark_databricks_io_cache_maxDiskUsage" {
  description = "spark_databricks_io_cache_maxDiskUsage from spark_conf"
  type        = string
  nullable    = false
}
variable "spark_databricks_io_cache_maxMetaDataCache" {
  description = "spark_databricks_io_cache_maxMetaDataCache from spark_conf"
  type        = string
  nullable    = false
}
variable "spark_databricks_delta_preview_enabled" {
  description = "spark_databricks_delta_preview_enabled from spark_conf"
  type        = string
  nullable    = false
}
variable "spark_databricks_aggressiveWindowDownS" {
  description = "spark.databricks.aggressiveWindowDownS from spark_conf"
  type        = string
  nullable    = false
}
variable "spark_databricks_env" {
  description = "ENVIRONMENT from spark_env_vars"
  type        = string
  nullable    = false
}
variable "spark_databricks_pyspark_python" {
  description = "PYSPARK_PYTHON from spark_env_vars"
  type        = string
  nullable    = false
}
variable "availability" {
  description = "availability from azure_attributes"
  type        = string
  nullable    = false
}
variable "first_on_demand" {
  description = "first_on_demand from azure_attributes"
  type        = string
  nullable    = false
}
variable "spot_bid_max_price" {
  description = "spot_bid_max_price from azure_attributes"
  type        = string
  nullable    = false
}

variable "python_package" {
  description = "Python package to install"
  type        = string
}

variable "spnclientid" {
  description = "Airflow service principal client id."
  type        = string
  sensitive   = true
}

variable "db_workspace_id" {
  description = "Databricks workspace id"
  type        = string
}

variable "db_workspace_host" {
  description = "Databricks workspace host url"
  type        = string
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
  default     = {}
}

variable "init_script_workspace" {
  description = "Init script location"
  type        = string
}