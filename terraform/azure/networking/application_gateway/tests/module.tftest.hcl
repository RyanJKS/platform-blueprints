mock_provider "azurerm" {}

variables {
  settings            = { name_prefix = "paymentsuksdev", region_long = "uksouth" }
  resource_group_name = "rg-test"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/example/subnets/gateway"
  frontend_ip_configurations = {
    public = { public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/example" }
  }
  frontend_ports        = { http = 80 }
  backend_address_pools = { app = { fqdns = ["app.example.com"] } }
  backend_http_settings = { app = { port = 80 } }
  http_listeners        = { http = { frontend_ip_configuration_name = "public", frontend_port_name = "http" } }
  request_routing_rules = { app = { priority = 100, http_listener_name = "http", backend_address_pool_name = "app", backend_http_settings_name = "app" } }
}

run "basic_defaults" {
  command = plan
  assert {
    condition = (
      output.name == "paymentsuksdevagw" && output.location == "uksouth" &&
      azurerm_application_gateway.this.sku[0].tier == "Standard_v2" &&
      azurerm_application_gateway.this.sku[0].capacity == 2 &&
      length(azurerm_application_gateway.this.autoscale_configuration) == 0 &&
      length(azurerm_public_ip.this) == 0 &&
      one(azurerm_application_gateway.this.frontend_ip_configuration).public_ip_address_id == var.frontend_ip_configurations.public.public_ip_address_id &&
      one(azurerm_application_gateway.this.request_routing_rule).priority == 100 &&
      one(azurerm_application_gateway.this.backend_address_pool).fqdns == toset(["app.example.com"])
    )
    error_message = "Defaults must preserve naming, fixed v2 capacity, and backend routing."
  }
}

run "https_waf_autoscaling" {
  command = plan
  variables {
    name                    = "custom-gateway"
    location                = "westeurope"
    sku                     = { tier = "WAF_v2" }
    autoscale_configuration = { min_capacity = 1, max_capacity = 5 }
    firewall_policy_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/example"
    identity_ids            = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/gateway"]
    ssl_certificates        = { frontend = { key_vault_secret_id = "https://example.vault.azure.net/secrets/frontend" } }
    frontend_ports          = { https = 443 }
    http_listeners          = { https = { frontend_ip_configuration_name = "public", frontend_port_name = "https", protocol = "Https", ssl_certificate_name = "frontend", host_name = "app.example.com", require_sni = true } }
    request_routing_rules   = { app = { priority = 100, http_listener_name = "https", backend_address_pool_name = "app", backend_http_settings_name = "app" } }
    probes                  = { ready = { host = "app.example.com", path = "/health", match = { status_code = ["200"] } } }
    backend_http_settings   = { app = { port = 443, protocol = "Https", host_name = "app.example.com", probe_name = "ready", connection_draining = { drain_timeout_sec = 60 } } }
  }
  assert {
    condition = (
      output.name == "custom-gateway" && output.location == "westeurope" &&
      azurerm_application_gateway.this.autoscale_configuration[0].max_capacity == 5 &&
      azurerm_application_gateway.this.firewall_policy_id == var.firewall_policy_id &&
      one(azurerm_application_gateway.this.ssl_certificate).key_vault_secret_id == var.ssl_certificates.frontend.key_vault_secret_id &&
      one(azurerm_application_gateway.this.http_listener).protocol == "Https" &&
      one(azurerm_application_gateway.this.backend_http_settings).probe_name == "ready" &&
      one(azurerm_application_gateway.this.backend_http_settings).connection_draining[0].drain_timeout_sec == 60
    )
    error_message = "HTTPS, WAF, autoscaling, probes, and draining must reach the gateway."
  }
}

run "private_path_routing" {
  command = plan
  variables {
    frontend_ip_configurations = { private = { private_ip_address = "10.0.1.10" } }
    http_listeners             = { http = { frontend_ip_configuration_name = "private", frontend_port_name = "http" } }
    request_routing_rules      = { app = { priority = 100, http_listener_name = "http", rule_type = "PathBasedRouting", url_path_map_name = "paths" } }
    url_path_maps = {
      paths = {
        default_backend_address_pool_name  = "app"
        default_backend_http_settings_name = "app"
        path_rules                         = [{ name = "api", paths = ["/api/*"], backend_address_pool_name = "app", backend_http_settings_name = "app" }]
      }
    }
  }
  assert {
    condition = (
      one(azurerm_application_gateway.this.frontend_ip_configuration).private_ip_address == "10.0.1.10" &&
      one(azurerm_application_gateway.this.frontend_ip_configuration).subnet_id == var.subnet_id &&
      one(azurerm_application_gateway.this.request_routing_rule).url_path_map_name == "paths" &&
      one(azurerm_application_gateway.this.url_path_map).path_rule[0].paths == tolist(["/api/*"])
    )
    error_message = "Private frontends and ordered path rules must be preserved."
  }
}

run "reject_missing_listener_reference" {
  command = plan
  variables {
    request_routing_rules = { app = { priority = 100, http_listener_name = "missing", backend_address_pool_name = "app", backend_http_settings_name = "app" } }
  }
  expect_failures = [azurerm_application_gateway.this]
}

run "reject_waf_without_policy" {
  command = plan
  variables { sku = { tier = "WAF_v2" } }
  expect_failures = [azurerm_application_gateway.this]
}

run "reject_duplicate_priorities" {
  command = plan
  variables {
    request_routing_rules = {
      first  = { priority = 100, http_listener_name = "http", backend_address_pool_name = "app", backend_http_settings_name = "app" }
      second = { priority = 100, http_listener_name = "http", backend_address_pool_name = "app", backend_http_settings_name = "app" }
    }
  }
  expect_failures = [var.request_routing_rules]
}

run "reject_invalid_autoscale" {
  command = plan
  variables { autoscale_configuration = { min_capacity = 5, max_capacity = 2 } }
  expect_failures = [var.autoscale_configuration]
}

run "managed_public_frontend" {
  command = apply
  variables {
    add_public_ip              = true
    frontend_ip_configurations = {}
  }
  assert {
    condition = (
      length(azurerm_public_ip.this) == 1 &&
      azurerm_public_ip.this[0].name == "paymentsuksdevpip" &&
      azurerm_public_ip.this[0].location == "uksouth" &&
      azurerm_public_ip.this[0].resource_group_name == var.resource_group_name &&
      azurerm_public_ip.this[0].sku == "Standard" &&
      azurerm_public_ip.this[0].allocation_method == "Static" &&
      one(azurerm_application_gateway.this.frontend_ip_configuration).name == "public" &&
      one(azurerm_application_gateway.this.frontend_ip_configuration).public_ip_address_id == azurerm_public_ip.this[0].id
    )
    error_message = "Enabling add_public_ip must create and attach a Standard static public IP without caller-supplied frontends."
  }
}
run "managed_public_frontend_merges_private_and_overrides_matching_key" {
  command = apply
  variables {
    add_public_ip                = true
    public_ip_name               = "custom-public-ip"
    public_ip_configuration_name = "external"
    location                     = "westeurope"
    zones                        = ["1", "2", "3"]
    tags                         = { environment = "test" }
    frontend_ip_configurations = {
      external = { public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/existing" }
      private  = { private_ip_address = "10.0.1.10" }
    }
    http_listeners = {
      http = { frontend_ip_configuration_name = "external", frontend_port_name = "http" }
    }
  }
  assert {
    condition = (
      azurerm_public_ip.this[0].name == "custom-public-ip" &&
      azurerm_public_ip.this[0].location == "westeurope" &&
      azurerm_public_ip.this[0].zones == var.zones &&
      azurerm_public_ip.this[0].tags == var.tags &&
      length(azurerm_application_gateway.this.frontend_ip_configuration) == 2 &&
      one([for f in azurerm_application_gateway.this.frontend_ip_configuration : f if f.name == "external"]).public_ip_address_id == azurerm_public_ip.this[0].id &&
      one([for f in azurerm_application_gateway.this.frontend_ip_configuration : f if f.name == "private"]).private_ip_address == "10.0.1.10" &&
      one([for f in azurerm_application_gateway.this.frontend_ip_configuration : f if f.name == "private"]).subnet_id == var.subnet_id
    )
    error_message = "The managed public frontend must override its matching key, preserve the private frontend, and honor naming, region, zones, and tags."
  }
}
run "reject_empty_frontends_without_managed_public_ip" {
  command = plan
  variables {
    frontend_ip_configurations = {}
  }
  expect_failures = [azurerm_application_gateway.this]
}
