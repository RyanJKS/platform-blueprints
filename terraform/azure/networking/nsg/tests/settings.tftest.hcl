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
    condition     = azurerm_network_security_group.this.name == "paymentsuksdevnsg" && azurerm_network_security_group.this.location == "uksouth"
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
    condition     = azurerm_network_security_group.this.name == "explicit-resource" && azurerm_network_security_group.this.location == "westeurope"
    error_message = "Explicit inputs must override shared settings."
  }
}
