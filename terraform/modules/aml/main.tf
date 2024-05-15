resource "azurerm_machine_learning_workspace" "amlw" {
  name                          = var.name_aml
  location                      = var.location
  resource_group_name           = var.resource_group_name
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  container_registry_id         = var.acr_id
  public_network_access_enabled = var.public_network_access_enabled
  identity {
    type = var.identity_type
  }
  tags = var.tags
}

resource "azurerm_role_assignment" "assign" {
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.amlw.identity[0].principal_id
  scope                = var.subscription_id
}
#TODO: We need to review role assignment for aml
/* resource "azurerm_role_assignment" "role_aks_primary_network" {
  role_definition_name             = "Storage Blob Data Reader"
  principal_id                     = azurerm_machine_learning_workspace.amlw.identity[0].principal_id
  scope                            = var.storage_account_id_aml2
  skip_service_principal_aad_check = true
}
 */
resource "azurerm_private_endpoint" "ws_pe" {
  name                = var.pe_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.vnet_subnet_aks_aml
  private_service_connection {
    name                           = var.psc_name
    private_connection_resource_id = azurerm_machine_learning_workspace.amlw.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = var.psz_group_name
    private_dns_zone_ids = var.private_dns_zone_ids
  }
  tags = var.tags
}

# Private Endpoint
# resource "azurerm_private_endpoint" "pe-aml" {
#   name                = var.pe_aml_name
#   location                      = var.location
#   resource_group_name           = var.resource_group_name
#   subnet_id           = var.vnet_subnet_aks_aml

#   private_service_connection {
#     name                           = var.pe_aml_name
#     private_connection_resource_id = azurerm_machine_learning_workspace.amlw.id
#     is_manual_connection           = false
#   }
# }

#Inference Cluster
# resource "azurerm_machine_learning_inference_cluster" "inference_cluster" {
#   name                  = var.inference_cluster_name
#   location              = var.location
#   cluster_purpose       = var.cluster_purpose
#   kubernetes_cluster_id = var.aks_cluster_id
#   description           = "Inference cluster with Terraform"
#   machine_learning_workspace_id = azurerm_machine_learning_workspace.amlw.id
#   tags = var.tags
# }

#Compute Instance
// resource "azurerm_machine_learning_compute_instance" "compute_instance" {
//   name                          = "cmp-ins-aml-${var.name_prefix}"
//   location                      = azurerm_resource_group.rg.location
//   machine_learning_workspace_id = azurerm_machine_learning_workspace.amlw.id
//   virtual_machine_size          = "STANDARD_A2_V2"
//   authorization_type            = "personal"
//   depends_on = [
//     tls_private_key.ssh,
//     azurerm_machine_learning_workspace.amlw
//   ]
//   ssh {
//     public_key = tls_private_key.ssh.public_key_openssh
//   }
//   subnet_resource_id = azurerm_subnet.subnet.id
//   description        = "Compute Instance with Terraform"
//   tags = var.common_tags
// }