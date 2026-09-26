output "id" {
  description = "The id of the resource."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "The name of the resource."
  value       = azurerm_user_assigned_identity.this.name
}

output "location" {
  description = "The location of the resource."
  value       = azurerm_user_assigned_identity.this.location
}

output "tags" {
  description = "The tags of the resource."
  value       = azurerm_user_assigned_identity.this.tags
}

output "client_id" {
  description = "The client id of the resource."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = "The principal id of the resource."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "tenant_id" {
  description = "The tenant id of the resource."
  value       = azurerm_user_assigned_identity.this.tenant_id
}
