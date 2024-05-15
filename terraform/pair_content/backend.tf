terraform {
  backend "azurerm" {
    key              = "pair_content.tfstate"
    use_azuread_auth = true
  }
}