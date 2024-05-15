data "azurerm_client_config" "current" {}

data "azurerm_subscription" "primary" {}

data "azuread_service_principal" "spn" {
  object_id = data.azurerm_client_config.current.object_id
}

data "terraform_remote_state" "enablers" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.remote_state.resource_group_name
    storage_account_name = local.remote_state.storage_account_name
    container_name       = local.remote_state.container_name
    key                  = "enablers.tfstate"
    use_azuread_auth     = local.remote_state.use_azuread_auth
  }
}