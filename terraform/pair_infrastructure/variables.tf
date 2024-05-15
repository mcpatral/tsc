variable "PROJECT" {
  type        = string
  description = "Project name"
}
variable "ENVIRONMENT_TYPE" {
  type        = string
  description = "Environment type (dev, test, uat, prod)"
}

variable "SUBSCRIPTION_TYPE" {
  type        = string
  description = "Subscription type"
}

variable "LOCATION" {
  type        = string
  description = "Azure region name"
}

variable "LOCATION_SHORT" {
  type        = string
  description = "Azure region short name"
}

variable "PAIR_LOCATION" {
  type        = string
  description = "Azure pair region name"
}

variable "PAIR_LOCATION_SHORT" {
  type        = string
  description = "Azure pair region short name"
}

variable "PAIR_PAAS" {
  type        = bool
  description = "Pair paas"
}

variable "PAIR_CENTRAL_LAW_ID" {
  # TODO: Remove/Replace default value to actual LAW ID. Currently, it is temporary LAW created by us.
  type        = string
  default     = null
  description = "Central Log Analytics Workspace ID"
}

variable "ACR_SKU" {
  type        = string
  description = "The SKU name of the the container registry. Possible values are Basic, Standard and Premium."

  validation {
    condition = contains([
      "Basic",
      "Standard",
      "Premium"
    ], var.ACR_SKU)
    error_message = "Only 'Basic', 'Standard' and 'Premium' values are allowed"
  }
}

variable "POSTGRES_SKU" {
  type        = string
  description = "The SKU Name for the PostgreSQL Flexible Server. The name of the SKU, follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)."
}

variable "STORAGE_MB" {
  type        = string
  description = "The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, and 16777216."
  default     = "32768"
}

variable "ADDITIONAL_AUTHORIZED_IPS" {
  type        = string
  default     = ""
  description = "Comma-separated IP/CIDR list of additional addreses to allow work with AKS API and KV API"
}

variable "AKS_OMS_AGENT_ENABLED" {
  type        = bool
  description = "AKS OMS agent enabled"
  default     = false
}

variable "MAIN_AKS_SIZE" {
  type        = string
  description = "AKS VM node size for main"
  default     = "Standard_DS2_v2"
}

variable "MAIN_AKS_NODE_COUNT" {
  type        = string
  description = "AKS VM node count for main"
  default     = "3"
}

variable "MAIN_AKS_NODE_MAX_COUNT" {
  type        = string
  description = "AKS VM max node count for main"
  default     = "3"
}

variable "MAIN_AKS_NODE_MAX_PODS" {
  type        = string
  description = "AKS VM max pod count for main"
  default     = "30"
}

variable "DATABRICKS_SKU" {
  type        = string
  description = "IP mapping"
}

variable "PROVISION_DATABRICKS_CLUSTERSIZE" {
  type        = string
  description = "Any supported databricks_node_type id"
}