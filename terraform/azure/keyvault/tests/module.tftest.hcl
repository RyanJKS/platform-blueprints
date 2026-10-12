mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      object_id = "33333333-3333-3333-3333-333333333333"
    }
  }

  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/test-resource"
    }
  }
}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
  name                = "test-resource"
  resource_group_name = "rg-test"
  location            = "uksouth"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
}

run "secure_defaults" {
  command = plan
  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled && azurerm_key_vault.this.purge_protection_enabled && !azurerm_key_vault.this.public_network_access_enabled
    error_message = "The vault must use RBAC and purge protection with public access disabled."
  }
}

run "reject_short_retention" {
  command = plan
  variables {
    soft_delete_retention_days = 6
  }
  expect_failures = [var.soft_delete_retention_days]
}

run "current_identity_administrator" {
  command = apply

  assert {
    condition = (
      azurerm_role_assignment.creator.principal_id == "33333333-3333-3333-3333-333333333333"
      && azurerm_role_assignment.creator.role_definition_name == "Key Vault Administrator"
      && azurerm_role_assignment.creator.scope == azurerm_key_vault.this.id
      && output.creator_role_assignment_id == azurerm_role_assignment.creator.id
    )
    error_message = "When settings omit object_id, the current AzureRM identity must receive Key Vault Administrator scoped to the created vault."
  }
}

run "settings_identity_administrator" {
  command = apply

  variables {
    settings = {
      name_prefix = "paymentsuksdev"
      region_long = "uksouth"
      tenant_id   = "11111111-1111-1111-1111-111111111111"
      object_id   = "44444444-4444-4444-4444-444444444444"
    }
  }

  assert {
    condition = (
      azurerm_role_assignment.creator.principal_id == var.settings.object_id
      && azurerm_role_assignment.creator.principal_id != data.azurerm_client_config.current.object_id
      && azurerm_role_assignment.creator.scope == azurerm_key_vault.this.id
      && azurerm_role_assignment.creator.role_definition_name == "Key Vault Administrator"
    )
    error_message = "The object_id from solution settings must take precedence over the current AzureRM identity for the vault-scoped administrator assignment."
  }
}
