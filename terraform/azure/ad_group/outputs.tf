output "id" {
  description = "The id of the resource."
  value       = azuread_group.this.id
}

output "object_id" {
  description = "The group object ID for role assignments."
  value       = azuread_group.this.object_id
}

output "display_name" {
  description = "The display name of the resource."
  value       = azuread_group.this.display_name
}
