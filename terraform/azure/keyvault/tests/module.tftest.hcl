mock_provider "azurerm" {}

variables {
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
