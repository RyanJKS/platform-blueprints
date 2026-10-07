<!-- Frontmatter
name: Azure Application Gateway
description: Create an Application Gateway v2 with configurable frontends, TLS, backends, health probes, and routing.
tags: [azure, networking, application-gateway, module]
-->

# Azure Application Gateway

Create one `azurerm_application_gateway` using `Standard_v2` or `WAF_v2`. Configure public or static private frontends, HTTP/HTTPS listeners, basic or path-based routing, backend health probes, and fixed capacity or autoscaling.

Requires Terraform >= 1.3.0 and AzureRM >= 5.0.0. The caller configures the provider and backend. The module references existing infrastructure; it does not create a resource group, subnet, managed identity, Key Vault certificate, or WAF policy. It can optionally create a public IP.

## Inputs

Configuration maps use their keys as Azure configuration names. References between maps must use those keys.

| Input | Default | Description |
| --- | --- | --- |
| `settings` | Required | Object containing `name_prefix` and `region_long`. Accepts the shared solution settings output. |
| `resource_group_name` | Required | Existing resource group. |
| `subnet_id` | Required | Dedicated Application Gateway subnet. |
| `name` | `null` | Defaults to `${settings.name_prefix}agw`. |
| `location` | `null` | Defaults to `settings.region_long`. |
| `tags` | `{}` | Tags for the gateway and the optional managed public IP. |
| `sku` | `{}` | `tier` defaults to `"Standard_v2"`; also supports `"WAF_v2"`. Fixed `capacity` defaults to `2`. |
| `autoscale_configuration` | `null` | Optional `min_capacity` (default `2`) and `max_capacity` (default `10`). When configured, fixed SKU capacity is omitted. |
| `zones` | `[]` | Availability zones supported in the chosen region. |
| `http2_enabled` | `true` | Enable HTTP/2 on the frontend. |
| `identity_ids` | `[]` | User-assigned identities for Key Vault certificate access. |
| `firewall_policy_id` | `null` | Required for `WAF_v2`; must be omitted for `Standard_v2`. Create the policy in the caller. |
| `add_public_ip` | `false` | Create and attach a Standard static public IP using the gateway region, zones, and tags. |
| `public_ip_name` | `null` | Managed public IP name. Defaults to `${settings.name_prefix}pip`. |
| `public_ip_configuration_name` | `"public"` | Managed frontend name used by listeners. Overrides a matching map key when `add_public_ip` is enabled. |
| `frontend_ip_configurations` | `{}` | Map of `{ public_ip_address_id }` or `{ private_ip_address }`. Private frontends use `subnet_id` and static allocation. At least one entry is required unless `add_public_ip` is enabled. |
| `frontend_ports` | Required | Map of names to integer ports, such as `{ http = 80 }`. |
| `backend_address_pools` | Required | Map of objects with optional `fqdns` and `ip_addresses` sets. Both default to empty. |
| `backend_http_settings` | Required | Map of backend settings described below. |
| `http_listeners` | Required | Map of listener settings described below. |
| `request_routing_rules` | Required | Map of routing rules described below. |
| `url_path_maps` | `{}` | Map of default backends and ordered path rules. |
| `probes` | `{}` | Map of custom health probe settings. |
| `ssl_certificates` | `{}` | Map of `{ key_vault_secret_id }`; requires a gateway managed identity. Use versionless certificate **secret** IDs for rotation. |
| `trusted_root_certificates` | `{}` | Map of names to base64-encoded backend root certificates. |
| `ssl_policy_name` | `"AppGwSslPolicy20220101S"` | Predefined frontend TLS policy. |

### Backends, listeners, and routing

Each `backend_http_settings` entry requires `port`. Optional fields are `protocol` (`"Http"`), `cookie_based_affinity` (`"Disabled"`), `request_timeout` (`30` seconds), `host_name`, `pick_host_name_from_backend_address` (`false`), `path`, `probe_name`, and `trusted_root_certificate_names` (`[]`). Optional `connection_draining` accepts `enabled` (`true`) and `drain_timeout_sec` (`30`). Select either an explicit hostname or backend hostname selection.

Each `http_listeners` entry requires `frontend_ip_configuration_name` and `frontend_port_name`. Optional fields are `protocol` (`"Http"`), `host_name`, `host_names` (`[]`), `require_sni` (`false`), and `ssl_certificate_name`. HTTPS requires a certificate reference; HTTP must omit it. Use either `host_name` or `host_names`.

Each `request_routing_rules` entry requires `priority` and `http_listener_name`. Priorities must be unique integers from 1 to 20000. The default `rule_type = "Basic"` requires `backend_address_pool_name` and `backend_http_settings_name`. Set `rule_type = "PathBasedRouting"` with `url_path_map_name` instead for path-based routing.

Each path map requires `default_backend_address_pool_name`, `default_backend_http_settings_name`, and `path_rules`. The ordered `path_rules` list contains objects with `name`, `paths`, `backend_address_pool_name`, and `backend_http_settings_name`. Put more specific paths before broad matches.

Each probe supports `protocol` (`"Http"`), `path` (`"/"`), `host`, `pick_host_name_from_backend_http_settings` (`false`), `interval` (`30` seconds), `timeout` (`30` seconds), `unhealthy_threshold` (`3`), and optional `port`. Set `host` or enable hostname selection. Optional `match` accepts `status_code` (`["200-399"]`) and `body`.

This module uses an external WAF policy and Key Vault frontend certificates. It does not expose inline WAF rules, uploaded PFX files, redirects, rewrite rules, or private-link configuration.

## Terraform example

The referenced subnet must already exist. An externally supplied public IP must also exist and use a compatible Standard SKU, static allocation, region, and zones.

To let the module create the public IP, set `add_public_ip = true` and omit `frontend_ip_configurations` for a public-only gateway. Listeners reference `"public"` by default, or the value of `public_ip_configuration_name`. You can also supply private frontend entries: the module merges the managed public frontend into the map and preserves entries with other keys. The managed entry takes precedence over a matching key.

```hcl
module "application_gateway" {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/networking/application_gateway?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"

  settings            = module.solution_settings.settings
  resource_group_name = azurerm_resource_group.network.name
  subnet_id           = azurerm_subnet.application_gateway.id
  tags                = module.solution_settings.tags

  frontend_ip_configurations = {
    public = { public_ip_address_id = azurerm_public_ip.application_gateway.id }
  }
  frontend_ports = { http = 80 }

  backend_address_pools = {
    app = { fqdns = ["app.internal.example.com"] }
  }
  backend_http_settings = {
    app = { port = 80, host_name = "app.internal.example.com" }
  }
  http_listeners = {
    http = {
      frontend_ip_configuration_name = "public"
      frontend_port_name             = "http"
    }
  }
  request_routing_rules = {
    app = {
      priority                   = 100
      http_listener_name         = "http"
      backend_address_pool_name  = "app"
      backend_http_settings_name = "app"
    }
  }
}
```

Replace the source revision and example backend with your deployment values. For HTTPS, add a port `443`, set listener `protocol = "Https"` and `ssl_certificate_name`, then supply `ssl_certificates` and `identity_ids`. Grant that identity the required Key Vault secret permissions and ensure network access to the vault. Put prerequisite role assignments in the module call's `depends_on` where needed.

For WAF, use `sku = { tier = "WAF_v2" }` with an existing `firewall_policy_id`. For autoscaling, add `autoscale_configuration = { min_capacity = 2, max_capacity = 10 }`.

The subnet needs sufficient address capacity and gateway-compatible NSG, routing, and DNS settings. Ensure the gateway can reach its backend endpoints. Private-only deployment availability and prerequisites depend on the Azure region and subscription; confirm support before using only a private frontend.

## Terragrunt and AKS dependencies

Use the same source path in a Terragrunt unit and pass the inputs above. Configure provider authentication and remote state in the consuming root. Read gateway outputs through a dependency:

```hcl
dependency "application_gateway" {
  config_path = "../application_gateway"
}

# In the AKS cluster unit:
inputs = {
  # Include the other required AKS inputs.
  ingress_application_gateway = {
    gateway_id = dependency.application_gateway.outputs.id
  }
}
```

Grant the AKS ingress addon identity the required gateway permissions separately. Application Gateway Ingress Controller (AGIC) changes gateway listeners, backends, and routing. This module manages those same fields: subsequent Terraform applies can overwrite AGIC changes. Establish a single owner for those fields before enabling AGIC; this module does not automatically ignore controller-managed configuration.

## Outputs

- `id`, `name`, `location`: Gateway resource identity.
- `identity`: Gateway managed identity settings.
- `backend_address_pool_ids`, `frontend_ip_configuration_ids`, `http_listener_ids`, `backend_http_settings_ids`: Resource IDs keyed by configuration name.

## Validation and upgrades

Review plans for replacement when changing gateway names, zones, subnet, or frontend settings. Tests require Terraform >= 1.7.0 and use a mocked AzureRM provider. They check module configuration, reference validation, and defaults without deploying Azure resources; they cannot verify live permissions, network reachability, or backend health.

```sh
terraform init -backend=false
terraform validate
terraform test
```
