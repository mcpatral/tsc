terraform {
  backend "azurerm" {
    key              = "pair_infrastructure.tfstate"
    use_azuread_auth = true
  }
}