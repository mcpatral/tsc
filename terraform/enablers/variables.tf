variable "PROJECT" {
  type        = string
  description = "Project name"
}

variable "ENVIRONMENT_TYPE" {
  type        = string
  description = "Environment type"
}

variable "ENVIRONMENT_DNS_ZONE_NAME" {
  type        = string
  description = "Environment DNS zone name"
}

variable "HUB_SUBSCRIPTION_ID" {
  type        = string
  default     = null
  description = "Subscription ID where Hub VNet is located"
}

variable "HUB_DNS_RESOURCE_GROUP_NAME" {
  type        = string
  default     = null
  description = "Resource group where DNS zones are located"
}

variable "FIREWALL_PUBLIC_IP" {
  type        = string
  default     = null
  description = "Hub network Azure Firewall Public IP address"
}

variable "FIREWALL_PRIVATE_IP" {
  type        = string
  default     = null
  description = "Hub network Azure Firewall Private IP address"
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

variable "LOCATION_SHORT_CENTRAL" {
  type        = string
  description = "Azure region short name for central resources"
}

variable "VNET_CIDR_BLOCKS" {
  type        = string
  description = "Comma-separated list of VNet CIDR blocks"
}

variable "VNET_PEERED" {
  type        = bool
  description = "Is VNet going to be peered to Hub network?"
}

variable "HUB_VNET_CIDR_BLOCK" {
  type        = string
  default     = null
  description = "Hub VNet CIDR block"
}

variable "SUBNET_DBW_PRIVATE_CIDR" {
  type        = string
  description = "CIDR block for Databricks Private subnet"
}

variable "SUBNET_DBW_PUBLIC_CIDR" {
  type        = string
  description = "CIDR block for Databricks Public subnet"
}

variable "SUBNET_ENDPOINTS_CIDR" {
  type        = string
  description = "CIDR block for endpoints subnet"
}

variable "SUBNET_POSTGRES_CIDR" {
  type        = string
  description = "CIDR block for Postgres subnet"
}

variable "SUBNET_AKS_PRIMARY_CIDR" {
  type        = string
  description = "CIDR block for AKS Primary cluster subnet"
}

variable "SUBNET_AKS_AML_CIDR" {
  type        = string
  description = "CIDR block for AKS AML cluster subnet"
}

variable "SUBNET_AKS_DEVOPS_CIDR" {
  type        = string
  description = "Comma-separated IP/CIDR list of additional addreses to allow work with AKS API"
}

variable "ADDITIONAL_AUTHORIZED_IPS" {
  type        = string
  default     = ""
  description = "Comma-separated IP/CIDR list of additional addreses to allow work with AKS API"
}

variable "CENTRAL_LAW_ID" {
  # TODO: Remove/Replace default value to actual LAW ID. Currently, it is temporary LAW created by us.
  type        = string
  default     = null
  description = "Central Log Analytics Workspace ID"
}

variable "DEVOPS_GROUP_ID" {
  type        = string
  description = "Azure AD DevOps group ID"
}

variable "DEVELOPER_GROUP_ID" {
  type        = string
  description = "Azure AD Developer group ID"
}

variable "QA_GROUP_ID" {
  type        = string
  description = "Azure AD QA group ID"
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

variable "DEVOPS_AKS_SIZE" {
  type        = string
  description = "AKS VM node size for main"
}

variable "DEVOPS_AKS_NODE_COUNT" {
  type        = number
  description = "AKS VM node count for main"
  default     = 2
}

variable "PAIR_PAAS" {
  type        = bool
  description = "Pair paas"
}

variable "AKS_OMS_AGENT_ENABLED" {
  type        = bool
  description = "AKS OMS agent enabled"
  default     = false
}

variable "CREATE_MONITOR_GLOBAL_ENTRIES" {
  type        = bool
  description = "Create Monitor endpoint global A records in DNS"
  default     = true
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

variable "NEXT_ENV_SPN_OBJECT_ID" {
  type        = string
  description = "Next controlled environment Service Principal object ID. Required for successful ACR sync of the next environment"
  default     = null
}

variable "DEVOPS_AKS_NODE_MAX_PODS" {
  type        = number
  description = "AKS VM max pod count for devops"
  default     = 30
}