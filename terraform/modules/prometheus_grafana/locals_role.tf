locals {
  amw_role_definition_id = "/subscriptions/${split("/", azurerm_monitor_workspace.amw.id)[2]}/providers/Microsoft.Authorization/roleDefinitions/b0d8363b-8ddd-447d-831f-62ca05bff136"
}