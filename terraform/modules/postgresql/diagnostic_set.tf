# TODO: Enable it as soon as project gets LAW ID of IT team or if needed
# resource "azurerm_monitor_diagnostic_setting" "psql" {
#   name                       = var.diagnostic_set_name
#   target_resource_id         = azurerm_postgresql_flexible_server.flexsrv.id
#   log_analytics_workspace_id = var.diagnostic_set_id

#   enabled_log {
#     category = "PostgreSQLLogs"
#   }

#   # Fixes Terraform resource update on each run even if no changes were made. Bug in provider.
#   # https://github.com/hashicorp/terraform-provider-azurerm/issues/10388
#   # TODO: Review what metrics we need and enable them if needed.
#   metric {
#     enabled  = false
#     category = "AllMetrics"
#   }
# }