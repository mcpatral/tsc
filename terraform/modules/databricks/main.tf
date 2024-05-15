resource "azurerm_databricks_workspace" "databricks" {
  name                                  = var.name_dbw
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  sku                                   = var.sku
  managed_resource_group_name           = var.managed_resource_group_name
  public_network_access_enabled         = var.public_network_access_enabled
  network_security_group_rules_required = var.network_security_group_rules_required

  custom_parameters {
    no_public_ip                                         = local.no_public_ip
    public_subnet_name                                   = var.public_subnet_name
    private_subnet_name                                  = var.private_subnet_name
    virtual_network_id                                   = var.virtual_network_id
    public_subnet_network_security_group_association_id  = var.public_subnet_network_security_group_association_id
    private_subnet_network_security_group_association_id = var.private_subnet_network_security_group_association_id
  }
  tags = var.tags
}
