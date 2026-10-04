output "id" {
  description = "The group resource IDs, keyed by group display name."
  value       = { for name, group in azuread_group.this : name => group.id }
}

output "object_id" {
  description = "The group object IDs for role assignments, keyed by group display name."
  value       = { for name, group in azuread_group.this : name => group.object_id }
}

output "display_name" {
  description = "The group display names, keyed by group display name."
  value       = { for name, group in azuread_group.this : name => group.display_name }
}

output "groups" {
  description = "Group details keyed by group display name."
  value = {
    for name, group in azuread_group.this : name => {
      id           = group.id
      object_id    = group.object_id
      display_name = group.display_name
    }
  }
}
