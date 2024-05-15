terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.102.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  storage_use_azuread        = local.provider_storage_use_azuread
}