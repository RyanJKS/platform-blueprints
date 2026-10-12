output "id" {
  description = "The registry Azure resource ID. Use this as the scope for AcrPull or AcrPush role assignments."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "The registry name."
  value       = azurerm_container_registry.this.name
}

output "location" {
  description = "The registry region from shared solution settings."
  value       = azurerm_container_registry.this.location
}

output "login_server" {
  description = "The registry login server hostname used to tag, push, and pull images."
  value       = azurerm_container_registry.this.login_server
}

output "data_endpoint_host_names" {
  description = "Dedicated data endpoint hostnames when enabled."
  value       = azurerm_container_registry.this.data_endpoint_host_names
}

output "identity" {
  description = "The registry managed identity, including principal and tenant IDs when available."
  value       = try(azurerm_container_registry.this.identity[0], null)
}

output "tags" {
  description = "The tags assigned to the registry."
  value       = azurerm_container_registry.this.tags
}

output "admin_username" {
  description = "The admin username, or null when the admin account is disabled."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_username : null
  sensitive   = true
}

output "admin_password" {
  description = "The admin password, or null when the admin account is disabled."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_password : null
  sensitive   = true
}
