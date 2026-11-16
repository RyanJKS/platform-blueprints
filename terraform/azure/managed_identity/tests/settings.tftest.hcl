mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
}

run "settings_defaults" {
  command = plan

  assert {
    condition     = azurerm_user_assigned_identity.this.name == "paymentsuksdevid" && azurerm_user_assigned_identity.this.location == "uksouth"
    error_message = "Shared settings must supply the default resource name and location."
  }
  assert {
    condition     = length(azurerm_key_vault_secret.client_id) == 0
    error_message = "Omitting key_vault_id must preserve identity-only behavior."
  }
}

run "explicit_overrides" {
  command = plan
  variables {
    name     = "explicit-resource"
    location = "westeurope"
  }
  assert {
    condition     = azurerm_user_assigned_identity.this.name == "explicit-resource" && azurerm_user_assigned_identity.this.location == "westeurope"
    error_message = "Explicit inputs must override shared settings."
  }
}

run "store_client_id" {
  command = apply

  variables {
    key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/test"
  }

  assert {
    condition = (
      azurerm_key_vault_secret.client_id[0].name == "paymentsuksdevid-client-id" &&
      azurerm_key_vault_secret.client_id[0].key_vault_id == var.key_vault_id &&
      azurerm_key_vault_secret.client_id[0].value == output.client_id
    )
    error_message = "Providing a vault must store this identity's client ID using the generated secret name."
  }
}

run "custom_secret_name_prefix" {
  command = plan

  variables {
    key_vault_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/test"
    secret_name_prefix = "external-dns"
  }

  assert {
    condition     = azurerm_key_vault_secret.client_id[0].name == "external-dns-client-id"
    error_message = "The explicit secret prefix must override the generated identity name."
  }
}

run "reject_empty_key_vault_id" {
  command = plan

  variables {
    key_vault_id = ""
  }

  expect_failures = [var.key_vault_id]
}
