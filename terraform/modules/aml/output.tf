output "machine_learning_workspace_identity_id" {
  description = "Machine learning workspace identity."
  value       = azurerm_machine_learning_workspace.amlw.identity[0].principal_id
}