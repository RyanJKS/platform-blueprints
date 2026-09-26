mock_provider "azurerm" {}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
  resource_group_name = "rg-test"
}

run "secure_defaults" {
  command = plan

  assert {
    condition = (
      azurerm_storage_account.this.https_traffic_only_enabled &&
      azurerm_storage_account.this.min_tls_version == "TLS1_2" &&
      !azurerm_storage_account.this.allow_nested_items_to_be_public &&
      azurerm_storage_account.this.public_network_access == "Disabled" &&
      !azurerm_storage_account.this.shared_access_key_enabled &&
      azurerm_storage_account.this.default_to_oauth_authentication
    )
    error_message = "The account must require HTTPS and TLS 1.2, default to OAuth, and disable public access and Shared Key authorization."
  }

  assert {
    condition = (
      output.name == "paymentsuksdevsa" && output.location == "uksouth" &&
      azurerm_storage_account.this.account_kind == "StorageV2" &&
      azurerm_storage_account.this.account_tier == "Standard" &&
      azurerm_storage_account.this.account_replication_type == "LRS" &&
      azurerm_storage_account.this.access_tier == "Hot"
    )
    error_message = "Shared settings must supply naming and location defaults for a Standard StorageV2 account with LRS and Hot storage."
  }
}

run "explicit_overrides" {
  command = plan

  variables {
    name                          = "explicitstorage123"
    location                      = "westeurope"
    account_replication_type      = "ZRS"
    access_tier                   = "Cool"
    public_network_access_enabled = true
    shared_access_key_enabled     = true
    tags                          = { environment = "test" }
  }

  assert {
    condition = (
      output.name == "explicitstorage123" && output.location == "westeurope" &&
      output.tags["environment"] == "test" &&
      azurerm_storage_account.this.account_replication_type == "ZRS" &&
      azurerm_storage_account.this.access_tier == "Cool" &&
      azurerm_storage_account.this.public_network_access == "Enabled" &&
      azurerm_storage_account.this.shared_access_key_enabled &&
      !azurerm_storage_account.this.allow_nested_items_to_be_public
    )
    error_message = "Explicit inputs must override defaults without enabling anonymous access."
  }
}

run "reject_invalid_name" {
  command = plan
  variables {
    name = "Invalid-Storage"
  }
  expect_failures = [azurerm_storage_account.this]
}

run "reject_long_generated_name" {
  command = plan
  variables {
    settings = {
      name_prefix = "abcdefghijklmnopqrstuvwxyz"
      region_long = "uksouth"
    }
  }
  expect_failures = [azurerm_storage_account.this]
}

run "reject_invalid_replication" {
  command = plan
  variables {
    account_replication_type = "INVALID"
  }
  expect_failures = [var.account_replication_type]
}

run "reject_invalid_access_tier" {
  command = plan
  variables {
    access_tier = "Archive"
  }
  expect_failures = [var.access_tier]
}
