terraform {
  backend "azurerm" {
    key              = "enablers.tfstate"
    use_azuread_auth = true
  }
}
