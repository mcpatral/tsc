variable "TENANT_NAME" {
  type        = string
  description = "Tenant environment name"
}

variable "PROJECT" {
  type        = string
  description = "Project name"
}

variable "ENVIRONMENT_TYPE" {
  type        = string
  description = "Environment type (dev, test, uat, prod)"
}

variable "LOCATION_SHORT" {
  type        = string
  description = "Azure region short name"
}

variable "TXB_OBJECT_ID" {
  type        = string
  description = "TXB object Id"
}
