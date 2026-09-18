output "id" {
  description = "The role assignment resource ID."
  value       = azurerm_role_assignment.this.id
}

output "name" {
  description = "The role assignment UUID."
  value       = azurerm_role_assignment.this.name
}

output "scope" {
  description = "The scope of the role assignment."
  value       = azurerm_role_assignment.this.scope
}

output "principal_id" {
  description = "The object ID of the assigned principal."
  value       = azurerm_role_assignment.this.principal_id
}

output "type" {
  description = "The assigned principal type."
  value       = azurerm_role_assignment.this.principal_type
}

output "role_definition_id" {
  description = "The resolved role definition resource ID."
  value       = azurerm_role_assignment.this.role_definition_id
}
