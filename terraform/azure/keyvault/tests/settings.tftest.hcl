mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
}

run "settings_defaults" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.name == "paymentsuksdevakv" && azurerm_key_vault.this.location == "uksouth"
    error_message = "Shared settings must supply the default resource name and location."
  }
  assert {
    condition     = azurerm_key_vault.this.tenant_id == var.settings.tenant_id
    error_message = "The vault must use the shared tenant ID."
  }
}

run "explicit_overrides" {
  command = plan
  variables {
    name      = "explicit-resource"
    location  = "westeurope"
    tenant_id = "22222222-2222-2222-2222-222222222222"
  }
  assert {
    condition     = azurerm_key_vault.this.name == "explicit-resource" && azurerm_key_vault.this.location == "westeurope"
    error_message = "Explicit inputs must override shared settings."
  }
  assert {
    condition     = azurerm_key_vault.this.tenant_id == var.tenant_id
    error_message = "The explicit tenant ID must override shared settings."
  }
}
