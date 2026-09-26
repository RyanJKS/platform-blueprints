mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  address_space       = ["10.0.0.0/16"]
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
}

run "settings_defaults" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this.name == "paymentsuksdevvnet" && azurerm_virtual_network.this.location == "uksouth"
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
    condition     = azurerm_virtual_network.this.name == "explicit-resource" && azurerm_virtual_network.this.location == "westeurope"
    error_message = "Explicit inputs must override shared settings."
  }
}
