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
