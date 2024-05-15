terraform {
  backend "azurerm" {
    key              = "content.tfstate"
    use_azuread_auth = true
  }
}