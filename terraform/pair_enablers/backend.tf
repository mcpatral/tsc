terraform {
  backend "azurerm" {
    key              = "pair_enablers.tfstate"
    use_azuread_auth = true
  }
}
