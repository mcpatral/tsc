#Azure Machine Learning does not support default storage-account failover using geo-redundant storage (GRS),
# geo-zone-redundant storage (GZRS), read-access geo-redundant storage (RA-GRS), or read-access geo-zone-redundant storage (RA-GZRS). 
#Create a separate storage account for the default storage of each workspace.
#https://learn.microsoft.com/en-us/azure/machine-learning/how-to-high-availability-machine-learning?view=azureml-api-1#plan-for-multi-regional-deployment

# module "aml" {
#   source = "../modules/aml"
#   #azurerm_machine_learning_workspace
#   name_aml                      = local.aml.name
#   location                      = var.LOCATION
#   resource_group_name           = local.enablers_tfstate_output.resource_group_name
#   tags                          = merge(local.common_tags, local.aml.tags)
#   application_insights_id       = local.aml.appinsights_id
#   key_vault_id                  = local.aml.key_vault_id
#   storage_account_id            = local.aml.storage_account_id
#   acr_id                        = local.aml.acr_id
#   public_network_access_enabled = local.aml.public_network_access_enabled
#   identity_type                 = local.aml.identity_type

#   #azurerm_role_assignment
#   subscription_id = data.azurerm_subscription.primary.id

#   #TODO When aml is enabled, please refactore private endpoints and take aml subresources out of the module
#   #azurerm_private_endpoint
#   pe_name             = "pe-aml-${local.name_base}"
#   vnet_subnet_aks_aml = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-endpoints"]
#   psc_name            = "psc-aml-${local.name_base}"
#   psz_group_name      = "psz-aml-${local.name_base}"
#   private_dns_zone_ids = [
#     local.enablers_tfstate_output.private_dns_zone_id["aml_api"],
#     local.enablers_tfstate_output.private_dns_zone_id["aml_notebooks"]
#   ]

#   #azurerm_machine_learning_inference_cluster
#   inference_cluster_name = "inf-aml-${local.name_base}"
#   aks_cluster_id         = module.aks["aml"].aks_id
#   cluster_purpose        = "FastProd"
# }

# resource "null_resource" "destroy_aml_workspace" {
#   triggers = {
#     name_base_no_dash   = local.name_base_no_dash
#     resource_group_name = local.enablers_tfstate_output.resource_group_name
#     subscription_id     = data.azurerm_subscription.primary.subscription_id
#   }
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<EOT
# az account set -s ${self.triggers.subscription_id}
# az extension add -n ml --version 2.17.2
# az ml workspace delete --name amlw${self.triggers.name_base_no_dash} --resource-group ${self.triggers.resource_group_name} --permanently-delete -y
# EOT
#   }
#   depends_on = [module.aml]
# }

# resource "null_resource" "create_or_destroy_access_policy" {
#   triggers = {
#     name_base               = local.name_base
#     resource_group_name     = local.enablers_tfstate_output.resource_group_name
#     object_id               = module.aml.machine_learning_workspace_identity_id
#     key-permissions         = "get list update create import delete"
#     secret-permissions      = "get list set delete"
#     certificate-permissions = "get list update create import delete"
#   }
#   provisioner "local-exec" {
#     when    = create
#     command = <<EOT
# az keyvault set-policy --name kv-${self.triggers.name_base}-aml --resource-group ${self.triggers.resource_group_name} --key-permissions ${self.triggers.key-permissions} --secret-permissions ${self.triggers.secret-permissions} --certificate-permissions ${self.triggers.certificate-permissions} --object-id ${self.triggers.object_id}
# EOT
#   }
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<EOT
# az keyvault delete-policy --name kv-${self.triggers.name_base}-aml --resource-group ${self.triggers.resource_group_name} --object-id ${self.triggers.object_id}
# EOT
#   }
#   depends_on = [module.aml]
# }