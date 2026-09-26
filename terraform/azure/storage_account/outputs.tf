output "id" {
  description = "The storage account resource ID."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The storage account name."
  value       = azurerm_storage_account.this.name
}

output "location" {
  description = "The Azure region of the storage account."
  value       = azurerm_storage_account.this.location
}

output "tags" {
  description = "The tags assigned to the storage account."
  value       = azurerm_storage_account.this.tags
}

output "primary_blob_endpoint" {
  description = "The primary Blob service endpoint. Network access and authorization are required separately."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "The primary dfs endpoint. Availability depends on the enabled services."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_file_endpoint" {
  description = "The primary file endpoint. Availability depends on the enabled services."
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_queue_endpoint" {
  description = "The primary queue endpoint. Availability depends on the enabled services."
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "The primary table endpoint. Availability depends on the enabled services."
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "primary_web_endpoint" {
  description = "The primary web endpoint. Availability depends on the enabled services."
  value       = azurerm_storage_account.this.primary_web_endpoint
}

output "identity" {
  description = "The managed identity configuration, including principal and tenant IDs when available."
  value       = azurerm_storage_account.this.identity
}
