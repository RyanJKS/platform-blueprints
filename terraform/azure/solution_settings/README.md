<!-- Frontmatter
name: Azure solution settings
description: Define shared solution settings and tags once for reuse across modules.
tags: [azure, module]
-->

# Azure solution settings

Groups shared solution inputs into a `settings` object and exposes `tags` separately.
This module creates no resources. It reads `azurerm_client_config.current` using
the caller's AzureRM provider configuration and authentication.
Requires Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.0.0.

Use this module when multiple consumers share the same settings contract. For a
single root module, a `locals` block can provide the same reuse with less structure.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `solution_name` | `string` | Yes | — | Shared solution name. |
| `env` | `string` | Yes | — | Environment name, such as `dev`. |
| `region_short` | `string` | Yes | — | Region abbreviation for names, such as `uks`. |
| `region_long` | `string` | Yes | — | Azure location identifier, such as `uksouth`. |
| `tags` | `map(string)` | No | `{}` | Shared resource tags. |

Region values are caller-defined; the module does not validate or derive their
mapping. Tags pass through unchanged. No tags are generated from other inputs.

## Outputs

- `settings`: An object containing `solution_name`, `solution_slug`, `name_suffix`,
  `env`, `region_short`, `region_long`, `subscription_id`, `tenant_id`,
  `client_id`, and `object_id`.
- `tags`: The input `var.tags` map returned directly, without inclusion in `settings`.

The four IDs describe the provider's current subscription and authenticated
identity. `client_id` is the client/application ID; `object_id` is the authenticated
principal's object ID. They are read from AzureRM, not supplied as module inputs.
For a different subscription or identity, pass a configured provider alias using
`providers = { azurerm = azurerm.target }`. Configure that provider independently;
using this module's outputs to configure its own provider creates a dependency cycle.

`solution_slug` lowercases and trims the solution name, replaces runs of characters
outside `a-z` and `0-9` with a hyphen, and removes leading and trailing hyphens.
For example, ` Payments API! ` becomes `payments-api`.

`name_suffix` combines `${solution_slug}-${env}-${region_short}`. With `env = "dev"`
and `region_short = "uks"`, the example produces `payments-api-dev-uks`.
Environment and region values are used unchanged. These naming values are not
truncated and do not guarantee uniqueness or compliance with resource-specific
naming rules. Resource modules should handle those rules and optional name
overrides. Use a solution name containing at least one ASCII letter or digit to
avoid an empty slug.

## Usage

The following paths assume the caller is beside the module directories in
`terraform/azure`. Adjust the paths for your root module.

```hcl
provider "azurerm" {
  features {}
  # Configure authentication and subscription through your usual AzureRM mechanism.
}

module "solution_settings" {
  source = "./solution_settings"

  solution_name = "payments"
  env           = "dev"
  region_short  = "uks"
  region_long   = "uksouth"
  tags = {
    environment = "dev"
    owner       = "platform"
  }
}

module "resource_group" {
  source = "./resource_group"

  name     = "rg-${module.solution_settings.settings.name_suffix}"
  location = module.solution_settings.settings.region_long
  tags     = module.solution_settings.tags
}
```

Consumers that only need tags can use `module.solution_settings.tags`. To add or
override tags for one resource, use `merge(module.solution_settings.tags, { cost_center = "1234" })`.
Both modules use the caller's AzureRM provider.
