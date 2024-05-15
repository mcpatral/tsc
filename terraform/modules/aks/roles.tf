resource "azurerm_role_assignment" "role_aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_role_assignment" "role_aks_network" {
  count                            = var.identity_type == "SystemAssigned" ? 1 : 0
  principal_id                     = azurerm_kubernetes_cluster.aks.identity.0.principal_id
  role_definition_name             = "Network Contributor"
  scope                            = var.vnet_id
  skip_service_principal_aad_check = true
}
