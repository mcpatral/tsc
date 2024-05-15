variable "sa_name" {
  description = "Storage account name"
  type        = string
}

variable "environment_type" {
  type        = string
  description = "Environtment for storage account(uat,sit,demo,test)"
}

variable "location_short" {
  type        = string
  description = "short name for location westeurope = weu"
  default     = "weu"
}
variable "location" {
  description = "Specifies the supported Azure location to MySQL server resource"
  type        = string
}

variable "resource_group_name" {
  description = "name of the resource group to create the resource"
  type        = string
}

variable "account_kind" {
  description = "Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2"
  type        = string
  default     = "StorageV2"
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account (Standard or Premium)."
  type        = string
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}
variable "access_tier" {
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts"
  type        = string
  default     = "Hot"

  validation {
    condition     = (contains(["hot", "cool"], lower(var.access_tier)))
    error_message = "The account_tier must be either \"Hot\" or \"Cool\"."
  }
}

variable "replication_type" {
  description = "Storage account replication type - i.e. LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  type        = string
  default     = "LRS"
}


# Note: make sure to include the IP address of the host from where "terraform" command is executed to allow for access to the storage
# Otherwise, creating container inside the storage or any access attempt will be denied.
variable "authorized_ips" {
  description = "Set of CIDRs Storage Account access."
  type        = set(string)
  default     = []
}


variable "service_endpoints" {
  description = "Creates a virtual network rule in the subnet_id (values are virtual network subnet ids)."
  type        = map(string)
  default     = {}
}

variable "subnet_service_endpoints" {
  description = "The subnet_id with service endpoint created."
  type        = list(string)
}

variable "traffic_bypass" {
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None."
  type        = list(string)
  default     = ["None"]
}

variable "shared_access_key_enabled" {
  description = "shared access key for storage account"
  type        = bool
  default     = true
}

variable "blob_cors" {
  description = "blob service cors rules:  https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account#cors_rule"
  type = map(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = null
}

variable "enable_static_website" {
  description = "Controls if static website to be enabled on the storage account. Possible values are `true` or `false`"
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Is NFSv3 protocol enabled? Changing this forces a new resource to be created"
  type        = bool
  default     = false
}

variable "default_network_rule" {
  description = "Specifies the default action of allow or deny when no other network rules match"
  type        = string
  default     = "Deny"

  validation {
    condition     = (contains(["deny", "allow"], lower(var.default_network_rule)))
    error_message = "The default_network_rule must be either \"Deny\" or \"Allow\"."
  }
}

variable "blob_versioning_enabled" {
  description = "Controls whether blob object versioning is enabled."
  type        = bool
  default     = false
}

variable "container_delete_retention_days" {
  description = "Retention days for deleted container. Valid value is between 1 and 365 (set to 0 to disable)."
  type        = number
  default     = 7
}

variable "delete_retention_days" {
  description = "Retention days for deleted for storage accounts."
  type        = number
  default     = 7
}

variable "is_hns_enabled" {
  description = "This can be used with Azure Data Lake Storage Gen 2"
  type        = bool
}
variable "public_network_access_enabled" {
  description = "public network access"
  type        = bool
}

variable "role_mappings" {
  type = map(object({
    principal_id         = string
    principal_type       = optional(string, "ServicePrincipal")
    role_definition_name = string
  }))
  default = {}
}

variable "key_vault_customer_managed_key_id" {
  description = "customer managed key"
  type        = string
  default     = null
}

variable "user_assigned_identity_id" {
  description = "user assigned identity id"
  type        = string
  default     = null
}

variable "databricks_access_connector_id" {
   description = "system assigned databricks identity id"
    type        = string
    default     = null 
}

variable "databricks_connector_assign_sa_list" {
  description = "The list of the storage accounts for Databricks connector"
  type        = list(string)
  default     = null
}