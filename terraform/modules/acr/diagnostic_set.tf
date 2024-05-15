# TODO: Enable it as soon as project gets LAW ID of IT team or if needed
# resource "azurerm_monitor_diagnostic_setting" "acr" {
#   name                       = "${azurerm_container_registry.registry.name}-logs"
#   target_resource_id         = azurerm_container_registry.registry.id
#   log_analytics_workspace_id = var.diagnostic_law_id

#   enabled_log {
#     category = "ContainerRegistryLoginEvents"
#   }

#   # Fixes Terraform resource update on each run even if no changes were made. Bug in provider.
#   # https://github.com/hashicorp/terraform-provider-azurerm/issues/10388
#   # TODO: Review what metrics we need and enable them if needed.
#   metric {
#     enabled  = false
#     category = "AllMetrics"
#   }
# }
