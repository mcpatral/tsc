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

variable "PAIR_LOCATION_SHORT" {
  type        = string
  description = "Azure pair region short name"
}

variable "PAIR_PAAS" {
  type        = bool
  description = "Pair paas"
}

variable "HUB_SUBSCRIPTION_ID" {
  type        = string
  default     = null
  description = "Subscription ID where Hub VNet is located"
}

variable "CENTRAL_LAW_ID" {
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

variable "POSTGRES_ZONE" {
  type        = string
  description = "PostgreSQL availability zone. Number of availability zones differs in different regions."
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

variable "VNET_PEERED" {
  type        = bool
  description = "Is VNet going to be peered to Hub network?"
}

variable "AKS_PRIVATE_CLUSTER" {
  type        = bool
  description = "Is AKS Main should be private?"
}

variable "FIREWALL_PUBLIC_IP" {
  type        = string
  default     = null
  description = "Hub network Azure Firewall Public IP address"
}

variable "RESTORE_FROM_PAIR_TO_MAIN" {
  type        = bool
  default     = false
  description = "Restore from pair to main"
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
  type        = number
  description = "AKS VM node count for main"
  default     = 2
}

variable "MAIN_AKS_NODE_MAX_COUNT" {
  type        = number
  description = "AKS VM max node count for main"
  default     = 4
}

variable "MAIN_AKS_NODE_MAX_PODS" {
  type        = number
  description = "AKS VM max pod count for main"
  default     = 30
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

variable "DATASCIENTIST_GROUP_ID" {
  type        = string
  description = "Azure AD Datascientist group ID"
}

#KEY VAULT SECRETS
variable "psqladminuser" {
  type        = string
  description = "Postgresql user name"
  sensitive   = true
}

variable "psqladminpwd" {
  type        = string
  description = "Postgresql user password"
  sensitive   = true
}
/*
variable "verticasuname" {
  type        = string
  description = "Vertica super user name"
  sensitive   = true
}

variable "verticasupassword" {
  type        = string
  description = "Vertica super user password"
  sensitive   = true
}

variable "verticatlskey" {
  type        = string
  description = "Vertica TLS internode key"
  sensitive   = true
}

variable "verticatlscrt" {
  type        = string
  description = "Vertica TLS internode certificate"
  sensitive   = true
}

variable "verticatlscakey" {
  type        = string
  description = "Vertica TLS CA key"
  sensitive   = true
}

variable "verticatlscacrt" {
  type        = string
  description = "Vertica TLS CA certificate"
  sensitive   = true
}

variable "verticatlswebhookkey" {
  type        = string
  description = "Vertica TLS webhook key"
  sensitive   = true
}

variable "verticatlswebhookcrt" {
  type        = string
  description = "Vertica TLS webhook certificate"
  sensitive   = true
}
*/

variable "airflowoauthspnclientid" {
  type        = string
  description = "Airflow OAuth service principal client id"
  sensitive   = true
}

variable "airflowoauthspnclientsecret" {
  type        = string
  description = "Airflow OAuth service principal client id"
  sensitive   = true
}

variable "airflowtenantid" {
  type        = string
  description = "Airflow service principal tenant id"
  sensitive   = true
}
/*
variable "verticadbwritername" {
  type        = string
  description = "Vertica DB writer name"
  sensitive   = true
}

variable "verticadbwriterpassword" {
  type        = string
  description = "Vertica DB writer password"
  sensitive   = true
}
*/
variable "airflowfernetkey" {
  type        = string
  description = "Airflow Fernet key"
  sensitive   = true
}

variable "airflowpwd" {
  type        = string
  description = "Airflow password"
  sensitive   = true
}

variable "databrickadmins" {
  type        = string
  description = "Databricks admins"
  sensitive   = true
}

variable "psqlairflowpwd" {
  type        = string
  description = "Airflow psql password"
  sensitive   = true
}

variable "psqlairflowuser" {
  type        = string
  description = "Airflow psql user"
  sensitive   = true
}
variable "clienttlskey" {
  type        = string
  description = "Client connections TLS key"
  sensitive   = true
}

variable "clienttlscrt" {
  type        = string
  description = "Client connections TLS certificate"
  sensitive   = true
}

variable "airflowsmtpclientsecret" {
  type        = string
  description = "Airflow SMTP Client Secret"
  sensitive   = true
}

variable "airflowsmtpclientid" {
  type        = string
  description = "Airflow SMTP Client Id"
  sensitive   = true
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

variable "SA_CFF2_SPN_OBJECT_ID" {
  type        = string
  description = "SA DL cff2 service principal object id"
  sensitive   = true
}

variable "SA_TEST_USER_ENABLED" {
  type        = bool
  description = "Enable test user Storage Blob Data Contributor"
}

variable "DATABRICKS_SKU" {
  type        = string
  description = "IP mapping"
}

variable "TXB_OBJECT_ID" {
  type        = string
  description = "TXB object Id"
}

variable "AIRFLOW_INTERNAL_DEV_EMAIL" {
  type        = string
  description = "Email for airflow notifications to dev team"
}

variable "DEVOPS_INTERNAL_EMAIL" {
  type        = string
  description = "Comma-separated list of emails for infrastructure metrics notifications to DevOps team"
}

variable "POSTGRES_MAX_CONNECTIONS" {
  type        = number
  description = "PostgreSQL server maximum connection number"
  default     = 100
}

variable "ACR_STORAGE_USAGE_ALERT" {
  type        = number
  description = "ACR storage usage alert threshold in GiB. If used more than this value, alert will be triggered"
  default     = 480
}

variable "SA_DL_STORAGE_USAGE_ALERT" {
  type        = number
  description = "Storage Account DL storage usage alert threshold in GiB. If used more than this value, alert will be triggered"
  default     = 38 # ~40 GB
}

variable "SA_TEMP_STORAGE_USAGE_ALERT" {
  type        = number
  description = "Storage Account Temp storage usage alert threshold in GiB. If used more than this value, alert will be triggered"
  default     = 19 # ~20 GB
}

variable "SA_AIRFLOW_STORAGE_USAGE_ALERT" {
  type        = number
  description = "Storage Account Airflow storage Usage alert threshold in GiB. If used more than this value, alert will be triggered"
  default     = 9 # 9.66 GB
}

variable "SA_LAW_STORAGE_USAGE_ALERT" {
  type        = number
  description = "Storage Account for Log Analytics Workspace storage usage alert threshold in GiB. If used more than this value, alert will be triggered"
  default     = 9 # 9.66 GB
}
