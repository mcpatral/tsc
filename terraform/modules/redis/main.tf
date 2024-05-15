resource "azurerm_redis_cache" "azure-redis" {
  name                          = var.redis_name
  location                      = var.location
  resource_group_name           = var.rg_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  enable_non_ssl_port           = var.enable_non_ssl_port
  minimum_tls_version           = local.redis_minimum_tls_version
  redis_version                 = var.redis_version
  tags                          = var.tags
  public_network_access_enabled = local.public_network_access_enabled
}