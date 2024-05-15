data "terraform_remote_state" "infrastructure" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.remote_state.resource_group_name
    storage_account_name = local.remote_state.storage_account_name
    container_name       = local.remote_state.container_name
    key                  = "infrastructure.tfstate"
    use_azuread_auth     = local.remote_state.use_azuread_auth
  }
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

data "azurerm_storage_account" "sa" {
  for_each            = local.storage_account.objects
  name                = "sa${local.name_base_no_dash}${each.key}"
  resource_group_name = data.terraform_remote_state.enablers.outputs.resource_group_name
}