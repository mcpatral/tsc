terraform {
  backend "azurerm" {
    key              = "infrastructure.tfstate"
    use_azuread_auth = true
  }
}