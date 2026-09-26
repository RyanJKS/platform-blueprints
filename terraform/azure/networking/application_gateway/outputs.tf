output "id" {
  description = "The Application Gateway resource ID."
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "The gateway name."
  value       = azurerm_application_gateway.this.name
}

output "location" {
  description = "The Azure region."
  value       = azurerm_application_gateway.this.location
}

output "identity" {
  description = "The gateway managed identity."
  value       = azurerm_application_gateway.this.identity
}

output "backend_address_pool_ids" {
  description = "Resource IDs keyed by configuration name."
  value       = { for item in azurerm_application_gateway.this.backend_address_pool : item.name => item.id }
}

output "frontend_ip_configuration_ids" {
  description = "Resource IDs keyed by configuration name."
  value       = { for item in azurerm_application_gateway.this.frontend_ip_configuration : item.name => item.id }
}

output "http_listener_ids" {
  description = "Resource IDs keyed by configuration name."
  value       = { for item in azurerm_application_gateway.this.http_listener : item.name => item.id }
}

output "backend_http_settings_ids" {
  description = "Resource IDs keyed by configuration name."
  value       = { for item in azurerm_application_gateway.this.backend_http_settings : item.name => item.id }
}

