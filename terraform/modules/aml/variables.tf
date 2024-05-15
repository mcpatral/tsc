variable "location" {
  type        = string
  description = "Region of Application Insights resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of Resource Group for AppInsights resource"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign for AML resources"
}

#azurerm_machine_learning_workspace
variable "name_aml" {
  type        = string
  description = "(Required) Specifies the name of the Machine Learning Workspace. Changing this forces a new resource to be created."
}

variable "application_insights_id" {
  type        = string
  description = "(Required) The ID of the Application Insights associated with this Machine Learning Workspace. Changing this forces a new resource to be created."
}

variable "key_vault_id" {
  type        = string
  description = "(Required) The ID of key vault associated with this Machine Learning Workspace. Changing this forces a new resource to be created."
}

variable "storage_account_id" {
  type        = string
  description = "(Required) The ID of the Storage Account associated with this Machine Learning Workspace. Changing this forces a new resource to be created."
}

variable "acr_id" {
  type        = string
  description = "(Optional) The ID of the container registry associated with this Machine Learning Workspace. Changing this forces a new resource to be created."
}

variable "public_network_access_enabled" {
  type        = string
  description = "(Optional) Enable public access when this Machine Learning Workspace is behind a VNet. Changing this forces a new resource to be created."
}

variable "identity_type" {
  type        = string
  description = "(Required) Specifies the type of Managed Service Identity that should be configured on this Machine Learning Workspace. Possible values are SystemAssigned, UserAssigned, SystemAssigned, UserAssigned (to enable both)."
}

#azurerm_role_assignment
variable "subscription_id" {
  type        = string
  description = "The subscription ID."
}
#TODO
/* variable "storage_account_id_aml2" {
  type        = string
  description = "(Required) The scope at which the Role Assignment applies to, such as /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333, /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup, or /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup/providers/Microsoft.Compute/virtualMachines/myVM, or /providers/Microsoft.Management/managementGroups/myMG. Changing this forces a new resource to be created."
}
 */

#azurerm_private_endpoint
variable "pe_name" {
  type        = string
  description = "(Required) Specifies the Name of the Private Endpoint. Changing this forces a new resource to be created."
}

variable "vnet_subnet_aks_aml" {
  type        = string
  description = "(Required) The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created."
}

variable "psc_name" {
  type        = string
  description = "(Required) Specifies the Name of the Private Service Connection. Changing this forces a new resource to be created."
}

variable "psz_group_name" {
  type        = string
  description = "(Required) Specifies the Name of the Private DNS Zone Group."
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "(Required) Specifies the list of Private DNS Zones to include within the private_dns_zone_group."
}

#azurerm_machine_learning_inference_cluster
variable "inference_cluster_name" {
  type        = string
  description = "How linked aks will be named as a compute resource"
}

variable "aks_cluster_id" {
  type        = string
  description = "AKS cluster id that needs to be linked to aml"
}

variable "cluster_purpose" {
  type        = string
  description = "Options are DevTest, DenseProd and FastProd. Depens on the workload"
}