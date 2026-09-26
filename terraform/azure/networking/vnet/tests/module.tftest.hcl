mock_provider "azurerm" {}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
  name                = "test-resource"
  resource_group_name = "rg-test"
  location            = "uksouth"
  address_space       = ["10.0.0.0/16"]
}

run "subnet_mapping" {
  command = plan
  variables {
    subnets = {
      aks       = { address_prefixes = ["10.0.0.0/22"] }
      endpoints = { address_prefixes = ["10.0.4.0/24"] }
    }
  }
  assert {
    condition     = toset(keys(output.subnet_ids)) == toset(["aks", "endpoints"])
    error_message = "Subnet outputs must preserve the caller's subnet names."
  }
}

run "reject_invalid_address_space" {
  command = plan
  variables {
    address_space = ["invalid"]
  }
  expect_failures = [var.address_space]
}

run "reject_empty_subnet_prefixes" {
  command = plan
  variables {
    subnets = { aks = { address_prefixes = [] } }
  }
  expect_failures = [var.subnets]
}
