terraform {
  backend "azurerm" {
    key              = "content-admin.tfstate"
    use_azuread_auth = true
  }
}