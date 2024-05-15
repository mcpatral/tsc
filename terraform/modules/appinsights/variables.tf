variable "name" {
  type        = string
  description = "Name of Application Insights resource"
}

variable "location" {
  type        = string
  description = "Region of Application Insights resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of Resource Group for AppInsights resource"
}

variable "application_type" {
  type        = string
  description = <<EOF
  Type of application for AppInsights
  Possible values: 'ios', 'java', 'MobileCenter', 'Node.JS', 'other', 'phone', 'store', 'web'
  EOF
}

variable "daily_data_cap_in_gb" {
  type        = number
  default     = 30
  description = "Application Insights resource daily data volume cap in GB"
}

variable "retention_in_days" {
  type        = number
  default     = 30
  description = "Specifies the retention period in days. Possible values are 30, 60, 90, 120, 180, 270, 365, 550 or 730"
}

variable "law_id" {
  type        = string
  default     = null
  description = "ID of Log Analytics Workspace for AppInsights resource"
}

variable "local_authentication_disabled" {
  type        = bool
  default     = false
  description = "Disable Non-Azure AD based Authentication"
}

variable "internet_query_enabled" {
  type        = bool
  default     = true
  description = "Application Insights resource support querying over the Public Internet"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign for AppInsights resource"
}