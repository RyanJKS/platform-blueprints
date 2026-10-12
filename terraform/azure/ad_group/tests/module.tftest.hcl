mock_provider "azuread" {}

variables {
  groups = {
    "aks-admins"      = {}
    "platform-reader" = {}
  }
}

run "security_groups" {
  command = plan

  assert {
    condition = (
      toset(keys(azuread_group.this)) == toset(["aks-admins", "platform-reader"]) &&
      alltrue([
        for name, group in azuread_group.this :
        group.display_name == name &&
        group.security_enabled &&
        !group.mail_enabled &&
        group.prevent_duplicate_names &&
        length(group.owners) == 0 &&
        length(group.members) == 0
      ])
    )
    error_message = "Each map key must create a security-only group with that display name and independent defaults."
  }
}

run "independent_group_settings" {
  command = plan

  variables {
    groups = {
      "aks-admins" = {
        description             = "AKS administrators"
        owners                  = ["00000000-0000-0000-0000-000000000001"]
        members                 = ["00000000-0000-0000-0000-000000000002"]
        prevent_duplicate_names = false
      }
      "platform-reader" = {
        description = "Platform readers"
        owners      = ["00000000-0000-0000-0000-000000000003"]
        members     = ["00000000-0000-0000-0000-000000000004"]
      }
    }
  }

  assert {
    condition = alltrue([
      for name, settings in var.groups :
      azuread_group.this[name].description == settings.description &&
      azuread_group.this[name].owners == settings.owners &&
      azuread_group.this[name].members == settings.members &&
      azuread_group.this[name].prevent_duplicate_names == settings.prevent_duplicate_names
    ])
    error_message = "Each group must retain its own description, owners, members, and duplicate-name setting."
  }
}

run "keyed_outputs" {
  command = apply

  assert {
    condition = (
      toset(keys(output.id)) == toset(keys(var.groups)) &&
      toset(keys(output.object_id)) == toset(keys(var.groups)) &&
      toset(keys(output.display_name)) == toset(keys(var.groups)) &&
      toset(keys(output.groups)) == toset(keys(var.groups)) &&
      alltrue([
        for name, group in azuread_group.this :
        output.id[name] == group.id &&
        output.object_id[name] == group.object_id &&
        output.display_name[name] == name &&
        output.groups[name].id == group.id &&
        output.groups[name].object_id == group.object_id &&
        output.groups[name].display_name == name
      ])
    )
    error_message = "All outputs must be keyed by group name and refer to the corresponding group."
  }
}

run "empty_groups" {
  command = plan
  variables {
    groups = {}
  }

  assert {
    condition = (
      length(azuread_group.this) == 0 &&
      length(output.id) == 0 &&
      length(output.object_id) == 0 &&
      length(output.display_name) == 0 &&
      length(output.groups) == 0
    )
    error_message = "An empty groups map must create no groups and return empty output maps."
  }
}

run "reject_empty_group_name" {
  command = plan
  variables {
    groups = { "" = {} }
  }
  expect_failures = [var.groups]
}

run "reject_whitespace_group_name" {
  command = plan
  variables {
    groups = { "   " = {} }
  }
  expect_failures = [var.groups]
}
