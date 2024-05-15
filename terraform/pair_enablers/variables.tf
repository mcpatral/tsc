variable "PROJECT" {
  type        = string
  description = "Project name"
}

variable "ENVIRONMENT_TYPE" {
  type        = string
  description = "Environment type"
}

variable "SUBSCRIPTION_TYPE" {
  type        = string
  description = "Subscription type"
}

variable "PAIR_LOCATION" {
  type        = string
  description = "Azure region name"
}

variable "PAIR_LOCATION_SHORT" {
  type        = string
  description = "Azure pair region short name"
}

variable "LOCATION_SHORT" {
  type        = string
  description = "Azure region short name"
}

variable "LOCATION_SHORT_CENTRAL" {
  type        = string
  description = "Azure region short name for central resources"
}

variable "PAIR_VNET_CIDR_BLOCKS" {
  type        = string
  description = "Comma-separated list of VNet CIDR blocks"
}

variable "PAIR_SUBNET_DBW_PRIVATE_CIDR" {
  type        = string
  description = "CIDR block for Databricks Private subnet"
}

variable "PAIR_SUBNET_DBW_PUBLIC_CIDR" {
  type        = string
  description = "CIDR block for Databricks Public subnet"
}

variable "PAIR_SUBNET_ENDPOINTS_CIDR" {
  type        = string
  description = "CIDR block for endpoints subnet"
}

variable "PAIR_SUBNET_POSTGRES_CIDR" {
  type        = string
  description = "CIDR block for Postgres subnet"
}

variable "PAIR_SUBNET_AKS_PRIMARY_CIDR" {
  type        = string
  description = "CIDR block for AKS Primary cluster subnet"
}

variable "PAIR_SUBNET_AKS_AML_CIDR" {
  type        = string
  description = "CIDR block for AKS AML cluster subnet"
}

variable "PAIR_SUBNET_AKS_DEVOPS_CIDR" {
  type        = string
  default     = ""
  description = "Comma-separated IP/CIDR list of additional addreses to allow work with AKS API"
}

variable "ADDITIONAL_AUTHORIZED_IPS" {
  type        = string
  default     = ""
  description = "Comma-separated IP/CIDR list of additional addreses to allow work with AKS API"
}

variable "PAIR_CENTRAL_LAW_ID" {
  # TODO: Remove/Replace default value to actual LAW ID. Currently, it is temporary LAW created by us.
  type        = string
  default     = null
  description = "Central Log Analytics Workspace ID"
}

variable "DEVOPS_GROUP_ID" {
  type = string
  description = "Azure AD DevOps group ID"
}

variable "DEVELOPER_GROUP_ID" {
  type = string
  description = "Azure AD Developer group ID"
}

variable "QA_GROUP_ID" {
  type = string
  description = "Azure AD QA group ID"
}

variable "DEVOPS_AKS_SIZE" {
  type        = string
  description = "AKS VM node size for main"
  default     = "Standard_DS2_v2"
}

variable "DEVOPS_AKS_NODE_COUNT" {
  type        = string
  description = "AKS VM node count for main"
  default     = "3"
}

variable "AKS_OMS_AGENT_ENABLED" {
  type        = bool
  description = "AKS OMS agent enabled"
  default     = false
}

variable "LAW_SKU" {
  type        = string
  description = "Log analytics workspace sku"
  default     = "PerGB2018"
}

variable "LAW_RETENTION_DAYS" {
  type        = number
  description = "Log analytics workspace sku"
  default     = 30
}