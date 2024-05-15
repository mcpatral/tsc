# TODO: Enable it as soon as project gets LAW ID of IT team or if needed
# #TODO retest with target law and content
# resource "azurerm_monitor_diagnostic_setting" "kv" {
#   name                       = var.diagnostic_set_name
#   target_resource_id         = azurerm_key_vault.kv.id
#   log_analytics_workspace_id = var.diagnostic_set_id

#   enabled_log {
#     category = "AuditEvent"
#   }

#   metric {
#     enabled  = false
#     category = "AllMetrics"
#   }
# }
