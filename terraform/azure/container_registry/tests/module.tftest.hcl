mock_provider "azurerm" {
  mock_resource "azurerm_container_registry" {
    defaults = {
      id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/paymentsuksdevacr"
      login_server   = "paymentsuksdevacr.azurecr.io"
      admin_username = "registry-admin"
      admin_password = "mock-password" # pragma: allowlist secret
    }
  }
}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
  resource_group_name = "rg-test"
}

run "defaults" {
  command = plan

  assert {
    condition = (
      output.name == "paymentsuksdevacr" &&
      output.location == "uksouth" &&
      azurerm_container_registry.this.resource_group_name == "rg-test" &&
      azurerm_container_registry.this.sku == "Basic" &&
      !azurerm_container_registry.this.admin_enabled &&
      !azurerm_container_registry.this.anonymous_pull_enabled &&
      azurerm_container_registry.this.public_network_access_enabled &&
      azurerm_container_registry.this.export_policy_enabled &&
      !azurerm_container_registry.this.data_endpoint_enabled &&
      !azurerm_container_registry.this.zone_redundancy_enabled &&
      output.admin_username == null && output.admin_password == null &&
      output.identity == null
    )
    error_message = "Defaults must use shared naming and region, Basic pricing, and authenticated access without admin credentials."
  }
}

run "normalize_generated_name" {
  command = plan
  variables {
    settings = {
      name_prefix = "Payments-UKS-dev"
      region_long = "westeurope"
    }
  }
  assert {
    condition     = output.name == "paymentsuksdevacr" && output.location == "westeurope"
    error_message = "Generated names must remove punctuation and use lowercase; location must follow settings."
  }
}

run "premium_features" {
  command = plan
  variables {
    name                       = "customregistry123"
    sku                        = "Premium"
    data_endpoint_enabled      = true
    zone_redundancy_enabled    = true
    network_rule_bypass_option = "None"
    network_rule_set = {
      ip_ranges = ["203.0.113.0/24"]
    }
    identity = { type = "SystemAssigned" }
    georeplications = [{
      location                        = "westeurope"
      zone_redundancy_enabled         = true
      global_endpoint_routing_enabled = false
      tags                            = { replica = "west" }
    }]
    tags = { environment = "test" }
  }
  assert {
    condition = (
      output.name == "customregistry123" &&
      output.location == "uksouth" &&
      output.tags["environment"] == "test" &&
      azurerm_container_registry.this.data_endpoint_enabled &&
      azurerm_container_registry.this.zone_redundancy_enabled &&
      azurerm_container_registry.this.network_rule_bypass_option == "None" &&
      azurerm_container_registry.this.network_rule_set[0].default_action == "Deny" &&
      one(azurerm_container_registry.this.network_rule_set[0].ip_rule).ip_range == "203.0.113.0/24" &&
      one(azurerm_container_registry.this.network_rule_set[0].ip_rule).action == "Allow" &&
      azurerm_container_registry.this.identity[0].type == "SystemAssigned" &&
      one(azurerm_container_registry.this.georeplications).location == "westeurope" &&
      one(azurerm_container_registry.this.georeplications).zone_redundancy_enabled &&
      !one(azurerm_container_registry.this.georeplications).global_endpoint_routing_enabled &&
      one(azurerm_container_registry.this.georeplications).tags["replica"] == "west"
    )
    error_message = "Premium settings, identity, firewall rules, and replicas must reach the registry resource."
  }
}

run "private_registry_without_exports" {
  command = plan
  variables {
    sku                           = "Premium"
    public_network_access_enabled = false
    export_policy_enabled         = false
  }
  assert {
    condition     = !azurerm_container_registry.this.public_network_access_enabled && !azurerm_container_registry.this.export_policy_enabled
    error_message = "Premium registries must support disabling public access and exports together."
  }
}

run "connection_and_admin_outputs" {
  command = apply
  variables {
    sku                    = "Standard"
    admin_enabled          = true
    anonymous_pull_enabled = true
  }
  assert {
    condition = (
      output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/paymentsuksdevacr" &&
      output.login_server == "paymentsuksdevacr.azurecr.io" &&
      output.admin_username == "registry-admin" &&
    output.admin_password == "mock-password" && # pragma: allowlist secret
      azurerm_container_registry.this.anonymous_pull_enabled
    )
    error_message = "The module must expose registry connection details and admin credentials only when enabled."
  }
}

run "reject_invalid_name" {
  command = plan
  variables { name = "invalid-name" }
  expect_failures = [azurerm_container_registry.this]
}

run "reject_long_generated_name" {
  command = plan
  variables {
    settings = {
      name_prefix = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
      region_long = "uksouth"
    }
  }
  expect_failures = [azurerm_container_registry.this]
}

run "reject_invalid_sku" {
  command = plan
  variables { sku = "Invalid" }
  expect_failures = [var.sku]
}

run "reject_basic_network_rules" {
  command = plan
  variables { network_rule_set = {} }
  expect_failures = [azurerm_container_registry.this]
}

run "reject_standard_replication" {
  command = plan
  variables {
    sku             = "Standard"
    georeplications = [{ location = "westeurope" }]
  }
  expect_failures = [azurerm_container_registry.this]
}

run "reject_basic_anonymous_pull" {
  command = plan
  variables { anonymous_pull_enabled = true }
  expect_failures = [azurerm_container_registry.this]
}

run "reject_public_registry_without_exports" {
  command = plan
  variables {
    sku                   = "Premium"
    export_policy_enabled = false
  }
  expect_failures = [azurerm_container_registry.this]
}

run "reject_primary_region_replica" {
  command = plan
  variables {
    sku             = "Premium"
    georeplications = [{ location = "uksouth" }]
  }
  expect_failures = [azurerm_container_registry.this]
}

run "reject_duplicate_replicas" {
  command = plan
  variables {
    sku             = "Premium"
    georeplications = [{ location = "westeurope" }, { location = "WestEurope" }]
  }
  expect_failures = [var.georeplications]
}

run "reject_invalid_firewall_action" {
  command = plan
  variables {
    sku              = "Premium"
    network_rule_set = { default_action = "Invalid" }
  }
  expect_failures = [var.network_rule_set]
}

run "reject_invalid_ip_range" {
  command = plan
  variables {
    sku              = "Premium"
    network_rule_set = { ip_ranges = ["invalid"] }
  }
  expect_failures = [var.network_rule_set]
}

run "reject_invalid_bypass" {
  command = plan
  variables { network_rule_bypass_option = "Invalid" }
  expect_failures = [var.network_rule_bypass_option]
}

run "reject_user_identity_without_ids" {
  command = plan
  variables { identity = { type = "UserAssigned" } }
  expect_failures = [var.identity]
}

run "reject_invalid_identity_type" {
  command = plan
  variables { identity = { type = "Invalid" } }
  expect_failures = [var.identity]
}
