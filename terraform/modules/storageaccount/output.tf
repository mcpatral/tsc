output "name" {
  value       = azurerm_storage_account.sa.name
  description = "The name of the Storage Account."
}

output "id" {
  value       = azurerm_storage_account.sa.id
  description = "The ID of the Storage Account."
}

output "primary_access_key" {
  value       = azurerm_storage_account.sa.primary_access_key
  sensitive   = true
  description = "The primary access key of the Storage Account."
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.sa.primary_blob_endpoint
  description = "The primary blob endpoint of the Storage Account."
}
