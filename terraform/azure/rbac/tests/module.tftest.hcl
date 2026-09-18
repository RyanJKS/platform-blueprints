mock_provider "azurerm" {}

variables {
  scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  principal_id         = "11111111-1111-1111-1111-111111111111"
  type                 = "Group"
  role_definition_name = "Reader"
}

run "group_role" {
  command = plan
  assert {
    condition     = output.type == "Group" && output.scope == var.scope && azurerm_role_assignment.this.role_definition_name == "Reader"
    error_message = "The group must receive the selected role at the requested scope."
  }
}

run "user_role" {
  command = plan
  variables {
    type = "User"
  }
  assert {
    condition     = output.type == "User"
    error_message = "User assignments must use the User principal type."
  }
}

run "new_managed_identity" {
  command = plan
  variables {
    type                             = "ServicePrincipal"
    skip_service_principal_aad_check = true
  }
  assert {
    condition     = output.type == "ServicePrincipal" && azurerm_role_assignment.this.skip_service_principal_aad_check
    error_message = "Managed identities must support bypassing the Entra replication check."
  }
}

run "custom_role_with_condition" {
  command = plan
  variables {
    role_definition_name = null
    role_definition_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/22222222-2222-2222-2222-222222222222"
    condition            = "(!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'}))"
  }
  assert {
    condition     = output.role_definition_id == var.role_definition_id && azurerm_role_assignment.this.condition == var.condition && azurerm_role_assignment.this.condition_version == "2.0"
    error_message = "Custom role IDs and ABAC conditions must be preserved with condition version 2.0."
  }
}

run "reject_unsupported_type" {
  command = plan
  variables {
    type = "ManagedIdentity"
  }
  expect_failures = [var.type]
}

run "reject_missing_role" {
  command = plan
  variables {
    role_definition_name = null
  }
  expect_failures = [azurerm_role_assignment.this]
}

run "reject_two_roles" {
  command = plan
  variables {
    role_definition_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/22222222-2222-2222-2222-222222222222"
  }
  expect_failures = [azurerm_role_assignment.this]
}

run "reject_group_check_bypass" {
  command = plan
  variables {
    skip_service_principal_aad_check = true
  }
  expect_failures = [azurerm_role_assignment.this]
}
