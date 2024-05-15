terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.102.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.36.2"
    }
  }
}
provider "azurerm" {
  features {}
  storage_use_azuread = local.storage_use_azuread
}

provider "databricks" {
  host = local.db_workspace_host
}
