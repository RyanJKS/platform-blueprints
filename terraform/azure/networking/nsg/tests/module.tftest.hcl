mock_provider "azurerm" {}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
  name                = "nsg-aks-test"
  resource_group_name = "rg-networking"
  location            = "uksouth"
}

run "no_custom_rules_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_network_security_rule.this) == 0
    error_message = "The module must not open any custom ports by default."
  }
}

run "https_and_optional_ssh" {
  command = plan
  variables {
    rules = {
      https = { priority = 1001
        direction             = "Inbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "443" }
      ssh = { priority = 1002
        direction             = "Inbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "22" }
    }
  }
  assert {
    condition     = toset(keys(output.rule_ids)) == toset(["https", "ssh"]) && azurerm_network_security_rule.this["https"].source_port_range == "*" && azurerm_network_security_rule.this["https"].destination_address_prefix == "*" && azurerm_network_security_rule.this["ssh"].source_address_prefix == "203.0.113.10/32"
    error_message = "The planned rules must match the requested configuration."
  }
}

run "multiple_prefixes_and_ports" {
  command = plan
  variables {
    rules = {
      https = { priority = 1001
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        source_address_prefixes = ["203.0.113.10/32", "198.51.100.10/32"]
      destination_port_ranges = ["443", "8443"] }
    }
  }
  assert {
    condition     = azurerm_network_security_rule.this["https"].source_address_prefix == null && length(azurerm_network_security_rule.this["https"].destination_port_ranges) == 2
    error_message = "The planned rules must match the requested configuration."
  }
}

run "application_security_groups" {
  command = plan
  variables {
    rules = {
      https = { priority = 1001
        direction                             = "Inbound"
        access                                = "Allow"
        protocol                              = "Tcp"
        source_application_security_group_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-networking/providers/Microsoft.Network/applicationSecurityGroups/clients"]
      destination_port_range = "443" }
    }
  }
  assert {
    condition     = length(azurerm_network_security_rule.this["https"].source_application_security_group_ids) == 1
    error_message = "The planned rules must match the requested configuration."
  }
}

run "same_priority_opposite_directions" {
  command = plan
  variables {
    rules = {
      inbound = { priority = 1001
        direction             = "Inbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "443" }
      outbound = { priority = 1001
        direction             = "Outbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "443" }
    }
  }
  assert {
    condition     = length(output.rule_ids) == 2
    error_message = "The planned rules must match the requested configuration."
  }
}

run "reject_duplicate_priority" {
  command = plan
  variables {
    rules = {
      first = { priority = 1001
        direction             = "Inbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "443" }
      second = { priority = 1001
        direction             = "Inbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "443" }
    }
  }
  expect_failures = [var.rules]
}

run "reject_invalid_priority" {
  command = plan
  variables {
    rules = {
      https = { priority = 99
        direction             = "Inbound"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "443" }
    }
  }
  expect_failures = [var.rules]
}

run "reject_invalid_direction" {
  command = plan
  variables {
    rules = {
      https = { priority = 1001
        direction             = "Incoming"
        access                = "Allow"
        protocol              = "Tcp"
        source_address_prefix = "203.0.113.10/32"
      destination_port_range = "443" }
    }
  }
  expect_failures = [var.rules]
}

run "reject_conflicting_ports" {
  command = plan
  variables {
    rules = {
      https = { priority = 1001
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_address_prefix  = "203.0.113.10/32"
        destination_port_range = "443"
      destination_port_ranges = ["443"] }
    }
  }
  expect_failures = [var.rules]
}

run "reject_conflicting_addresses" {
  command = plan
  variables {
    rules = {
      https = { priority = 1001
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_address_prefix  = "203.0.113.10/32"
        destination_port_range = "443"
      source_address_prefixes = ["203.0.113.10/32"] }
    }
  }
  expect_failures = [var.rules]
}

run "reject_empty_prefixes" {
  command = plan
  variables {
    rules = {
      https = { priority = 1001
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        source_address_prefixes = []
      destination_port_range = "443" }
    }
  }
  expect_failures = [var.rules]
}
