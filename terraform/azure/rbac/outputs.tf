output "id" {
  description = "The role assignment resource ID, keyed by assignment name."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.id }
}

output "name" {
  description = "The role assignment UUID, keyed by assignment name."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.name }
}

output "scope" {
  description = "The scope of the role assignment, keyed by assignment name."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.scope }
}

output "principal_id" {
  description = "The object ID of the assigned principal, keyed by assignment name."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.principal_id }
}

output "type" {
  description = "The assigned principal type, keyed by assignment name."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.principal_type }
}

output "role_definition_id" {
  description = "The resolved role definition resource ID, keyed by assignment name."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.role_definition_id }
}

output "assignments" {
  description = "Role assignment details keyed by the caller's assignment names."
  value = {
    for key, assignment in azurerm_role_assignment.this : key => {
      id                 = assignment.id
      name               = assignment.name
      scope              = assignment.scope
      principal_id       = assignment.principal_id
      type               = assignment.principal_type
      role_definition_id = assignment.role_definition_id
    }
  }
}
