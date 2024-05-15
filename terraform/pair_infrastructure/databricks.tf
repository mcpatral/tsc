module "databricks" {
  source = "../modules/databricks"
  #azurerm_databricks_workspace
  name_dbw                      = local.databricks.name_dbw
  location                      = var.PAIR_LOCATION
  resource_group_name           = local.enablers_tfstate_output.resource_group_name
  managed_resource_group_name   = local.databricks.managed_resource_group_name
  tags                          = merge(local.common_tags, try(local.databricks.tags,{}))
  sku                           = local.databricks.sku
  public_network_access_enabled = local.databricks.public_network_access_enabled
  #azurerm_databricks_workspace -> custom_parameters
  private_subnet_name                                  = local.databricks.private_subnet_name
  public_subnet_name                                   = local.databricks.public_subnet_name
  virtual_network_id                                   = local.enablers_tfstate_output.networks_vnet_id
  public_subnet_network_security_group_association_id  = local.databricks.public_subnet_network_security_group_association_id
  private_subnet_network_security_group_association_id = local.databricks.public_subnet_network_security_group_association_id

  #databricks_secret_scope
  secret_scope_name  = local.databricks.secret_scope_name
  key_vault_id       = local.databricks.key_vault_id
  key_vault_dns_name = local.databricks.key_vault_dns_name
}