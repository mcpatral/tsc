terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.102.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = local.provider_default_storage_use_azuread
}

provider "azurerm" {
  features {}
  storage_use_azuread = local.provider_sas_storage_use_azuread
  alias               = "sas"
}
