variable "location" {
  description = "The location of the postgresql flexible server."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Set of tags to assign to created resources"
}

variable "name_dbw" {
  description = "(Required) Specifies the name of the Databricks Workspace resource. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "managed_resource_group_name" {
  description = "(Optional) The name of the resource group where Azure should place the managed Databricks resources. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "sku" {
  description = "(Required) The sku to use for the Databricks Workspace. Possible values are standard, premium, or trial."
  type        = string
}

variable "public_network_access_enabled" {
  description = "(Optional) Allow public access for accessing workspace. Set value to false to access workspace only via private link endpoint. Possible values include true or false. Defaults to true."
  type        = string
  nullable    = false
}

variable "private_subnet_name" {
  description = "(Optional) The name of the Private Subnet within the Virtual Network. Required if virtual_network_id is set. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "public_subnet_name" {
  description = "(Optional) The name of the Public Subnet within the Virtual Network. Required if virtual_network_id is set. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "virtual_network_id" {
  description = "(Optional) The ID of a Virtual Network where this Databricks Cluster should be created. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "public_subnet_network_security_group_association_id" {
  description = "(Optional) The resource ID of the azurerm_subnet_network_security_group_association resource which is referred to by the public_subnet_name field. This is the same as the ID of the subnet referred to by the public_subnet_name field. Required if virtual_network_id is set."
  type        = string
  nullable    = false
}

variable "private_subnet_network_security_group_association_id" {
  description = "(Optional) The resource ID of the azurerm_subnet_network_security_group_association resource which is referred to by the private_subnet_name field. This is the same as the ID of the subnet referred to by the private_subnet_name field. Required if virtual_network_id is set."
  type        = string
  nullable    = false
}

variable "pair_databricks" {
  description = "Pair databricks"
  type        = bool
  default     = false
}

variable "network_security_group_rules_required" {
  description = "Specify what SG rules to be applied on workspace - Required when public_network_access_enabled = false"
  type        = string
  default     = "AllRules"
}
