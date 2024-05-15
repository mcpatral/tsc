# TODO: Enable it as soon as project gets LAW ID of IT team or if needed
# resource "azurerm_monitor_diagnostic_setting" "redis" {
#   name                       = var.diagnostic_set_name
#   target_resource_id         = azurerm_redis_cache.azure-redis.id
#   log_analytics_workspace_id = var.diagnostic_set_id

#   enabled_log {
#     category = "ConnectedClientList"
#   }
#   metric {
#     enabled  = false
#     category = "AllMetrics"
#   }
# }