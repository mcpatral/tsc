terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.102.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.29.0"
    }
  }
}
provider "azurerm" {
  features {}
  storage_use_azuread = local.storage_use_azuread
}