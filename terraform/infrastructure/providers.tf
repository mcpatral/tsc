terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.102.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.11.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.36.2"
    }
  }
}

provider "azurerm" {
  features {
    # Fixes issue when AppInsights resources are generation rules outside of Terraform
    # https://github.com/hashicorp/terraform-provider-azurerm/pull/15892
    # application_insights {
    #   disable_generated_rule = true
    # }
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
    }
  }
  storage_use_azuread = local.provider_default_storage_use_azuread
}

provider "azurerm" {
  features {}
  storage_use_azuread = local.provider_sas_storage_use_azuread
  alias               = "sas"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id            = var.HUB_SUBSCRIPTION_ID
  alias                      = "hub"
}

provider "azapi" {
  environment = "public"
}

provider "databricks" {
  host = module.databricks.db_workspace_host
  # azure_workspace_resource_id = module.databricks.databricks_id
  auth_type = "azure-cli"
}
