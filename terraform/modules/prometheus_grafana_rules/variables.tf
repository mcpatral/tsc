variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_group_id" {
  type        = string
  description = "ID of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region to use"
}

variable "amw_id" {
  type        = string
  description = "Azure monitor workspace ID"
}

variable "aks_cluster_name" {
  type        = string
  description = "Main aks cluster name"
}

variable "aks_cluster_id" {
  type        = string
  description = "Main aks cluster id"
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}