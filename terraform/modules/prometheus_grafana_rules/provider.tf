terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.69.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=1.7.0"
    }
  }
}
