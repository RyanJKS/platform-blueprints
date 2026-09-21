mock_provider "azurerm" {}

variables {
  assignments = {
    test = {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      principal_id         = "11111111-1111-1111-1111-111111111111"
      type                 = "Group"
      role_definition_name = "Reader"
    }
  }
}

run "group_role" {
  command = plan
  assert {
    condition     = output.type["test"] == "Group" && output.scope["test"] == var.assignments["test"].scope && azurerm_role_assignment.this["test"].role_definition_name == "Reader"
    error_message = "The group must receive the selected role at the requested scope."
  }
}

run "user_role" {
  command = plan
  variables {
    assignments = {
      test = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Reader"
        type                 = "User"
      }
    }
  }
  assert {
    condition     = output.type["test"] == "User"
    error_message = "User assignments must use the User principal type."
  }
}

run "new_managed_identity" {
  command = plan
  variables {
    assignments = {
      test = {
        scope                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id                     = "11111111-1111-1111-1111-111111111111"
        role_definition_name             = "Reader"
        type                             = "ServicePrincipal"
        skip_service_principal_aad_check = true
      }
    }
  }
  assert {
    condition     = output.type["test"] == "ServicePrincipal" && azurerm_role_assignment.this["test"].skip_service_principal_aad_check
    error_message = "Managed identities must support bypassing the Entra replication check."
  }
}

run "custom_role_with_condition" {
  command = plan
  variables {
    assignments = {
      test = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id         = "11111111-1111-1111-1111-111111111111"
        type                 = "Group"
        role_definition_name = null
        role_definition_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/22222222-2222-2222-2222-222222222222"
        condition            = "(!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'}))"
      }
    }
  }
  assert {
    condition     = output.role_definition_id["test"] == var.assignments["test"].role_definition_id && azurerm_role_assignment.this["test"].condition == var.assignments["test"].condition && azurerm_role_assignment.this["test"].condition_version == "2.0"
    error_message = "Custom role IDs and ABAC conditions must be preserved with condition version 2.0."
  }
}

run "reject_unsupported_type" {
  command = plan
  variables {
    assignments = {
      test = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Reader"
        type                 = "ManagedIdentity"
      }
    }
  }
  expect_failures = [var.assignments]
}

run "reject_missing_role" {
  command = plan
  variables {
    assignments = {
      test = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id         = "11111111-1111-1111-1111-111111111111"
        type                 = "Group"
        role_definition_name = null
      }
    }
  }
  expect_failures = [azurerm_role_assignment.this["test"]]
}

run "reject_two_roles" {
  command = plan
  variables {
    assignments = {
      test = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id         = "11111111-1111-1111-1111-111111111111"
        type                 = "Group"
        role_definition_name = "Reader"
        role_definition_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/22222222-2222-2222-2222-222222222222"
      }
    }
  }
  expect_failures = [azurerm_role_assignment.this["test"]]
}

run "reject_group_check_bypass" {
  command = plan
  variables {
    assignments = {
      test = {
        scope                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id                     = "11111111-1111-1111-1111-111111111111"
        type                             = "Group"
        role_definition_name             = "Reader"
        skip_service_principal_aad_check = true
      }
    }
  }
  expect_failures = [azurerm_role_assignment.this["test"]]
}

run "multiple_assignments" {
  command = plan
  variables {
    assignments = {
      platform_reader = {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
        principal_id         = "11111111-1111-1111-1111-111111111111"
        type                 = "Group"
        role_definition_name = "Reader"
      }
      identity_contributor = {
        scope                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-other"
        principal_id                     = "33333333-3333-3333-3333-333333333333"
        type                             = "ServicePrincipal"
        role_definition_name             = "Contributor"
        skip_service_principal_aad_check = true
      }
    }
  }
  assert {
    condition = (
      toset(keys(output.assignments)) == toset(["platform_reader", "identity_contributor"]) &&
      output.assignments["platform_reader"].principal_id == var.assignments["platform_reader"].principal_id &&
      output.scope["identity_contributor"] == var.assignments["identity_contributor"].scope &&
      azurerm_role_assignment.this["platform_reader"].role_definition_name == "Reader" &&
      azurerm_role_assignment.this["identity_contributor"].role_definition_name == "Contributor" &&
      !azurerm_role_assignment.this["platform_reader"].skip_service_principal_aad_check
    )
    error_message = "Each stable key must produce an independent assignment with its own settings and defaults."
  }
}

run "empty_assignments" {
  command = plan
  variables {
    assignments = {}
  }
  assert {
    condition     = length(azurerm_role_assignment.this) == 0 && length(output.assignments) == 0 && length(output.id) == 0
    error_message = "An empty map must create no role assignments and return empty outputs."
  }
}
