mock_provider "azurerm" {
  mock_resource "azurerm_dns_zone" {
    defaults = {
      name_servers = ["ns1.example.net.", "ns2.example.net."]
    }
  }
}

variables {
  name                = "example.com"
  resource_group_name = "rg-dns-test"
}

run "delegation_outputs" {
  command = apply

  assert {
    condition     = output.name == "example.com" && output.name_servers == toset(["ns1.example.net.", "ns2.example.net."])
    error_message = "The module must expose the zone name and provider-assigned nameservers for delegation."
  }
}
