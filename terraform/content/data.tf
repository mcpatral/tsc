data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

data "terraform_remote_state" "infrastructure" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.backend_rg_name
    storage_account_name = local.backend_sa_name
    container_name       = local.backend_container_name
    key                  = "infrastructure.tfstate"
    use_azuread_auth     = local.use_azuread_auth
  }
}