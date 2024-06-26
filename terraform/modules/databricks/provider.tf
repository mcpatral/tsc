terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.69.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">=1.29.0"
    }
  }
}
