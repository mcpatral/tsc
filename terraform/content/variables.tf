variable "PROJECT" {
  type        = string
  description = "Department of project"
}

variable "ENVIRONMENT_TYPE" {
  type        = string
  description = "Environment type (dev, test, uat, prod)"
}

variable "UNITY_CATALOG_ENVIRONMENT_TYPE" {
  type        = string
  description = "Environment type unity catalog groups (dev, test, uat, prod)"
}

variable "LOCATION_SHORT" {
  type        = string
  description = "Azure region short name"
}

variable "DATABRICKS_METASTORE_ID" {
  type        = string
  description = "Databricks metastore id"
}

variable "DATABRICKS_SCHEMAS" {
  type        = string
  description = "Comma-separated Databricks schemas"
}

variable "DATABRICKS_DEVOPS_GROUP" {
  type        = string
  description = "DevOps group name"
}

variable "DATABRICKS_DEV_GROUP" {
  type        = string
  description = "Developer group name"
}

variable "DATABRICKS_QA_GROUP" {
  type        = string
  description = "QA group name"
}

variable "DATABRICKS_DS_GROUP" {
  type        = string
  description = "DataScience group name"
}

variable "DATABRICKS_GROUP_IDS" {
  type        = string
  description = "Comma-separated suffixes for Databricks group ids"
}

variable "DATABRICKS_GROUP_SUFFIX" {
  type        = string
  description = "Comma-separated suffixes for Databricks groups"
}

variable "SINGLE_DATABRICKS_CLUSTERSIZE" {
  type        = string
  description = "Any supported databricks_node_type id"
}

variable "PROVISION_DATABRICKS_CLUSTERSIZE" {
  type        = string
  description = "Any supported databricks_node_type id"
}

variable "SINGLE_DATABRICKS_CLUSTERSIZE_DRIVER" {
  type        = string
  description = "Any supported databricks_node_type id"
}

variable "DATABRICKS_CLUSTER_AVAILABILITY" {
  type        = string
  description = "Databricks node availability type"
}

variable "PROVISION_DATABRICKS_CLUSTERSIZE_DRIVER" {
  type        = string
  description = "Any supported databricks_node_type id"
}

variable "DATABRICKS_AIRFLOW_GROUP_ID" {
  type        = string
  description = "Databricks Airflow group id"
}

variable "databrickadmins" {
  type        = string
  description = "Databricks account level group id that should be set as admin"
}

variable "DATABRICKS_AIRFLOW_GROUP_NAME" {
  type        = string
  description = "Databricks Airflow group name"
}

variable "SPN_DEVOPS_CLIENT_ID" {
  type        = string
  description = "Client id for spn-d-da-devops"
}

variable "airflowdbwspclientid" {
  type        = string
  description = "Airflow service principal client id"
  default     = null
  sensitive   = true
}

variable "airflowdbwspclientsecret" {
  type        = string
  description = "Airflow service principal client secret"
  default     = null
  sensitive   = true
}

variable "FORCE_DESTROY_SILVER_SCHEMAS" {
  type        = bool
  description = "Delete Silver schemas regardless empty it is or not"
  default     = false
}