variable "PROJECT" {
  type        = string
  description = "Department of project"
}

variable "ENVIRONMENT_TYPE" {
  type        = string
  description = "Environment type (dev, test, uat, prod)"
}

variable "LOCATION_SHORT" {
  type        = string
  description = "Azure region short name"
}

variable "DATABRICKS_METASTORE_ID" {
  type        = string
  description = "Databricks metastore id"
}

variable "DATABRICKS_ADMIN_GROUP" {
  type        = string
  description = "Any supported databricks_node_type id"
}

variable "DATABRICKS_ADMIN_GROUP_ID" {
  type        = string
  description = "Any supported databricks_node_type id"
}