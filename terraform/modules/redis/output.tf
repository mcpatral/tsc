output "redis_name" {
  value = azurerm_redis_cache.azure-redis.name
}

output "redis_port" {
  value = azurerm_redis_cache.azure-redis.port
}

output "redis_ssl_port" {
  value = azurerm_redis_cache.azure-redis.ssl_port
}
output "redis_key" {
  sensitive = true
  value     = azurerm_redis_cache.azure-redis.secondary_access_key
}