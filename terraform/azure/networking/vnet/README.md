<!-- Frontmatter
name: Azure virtual network
description: Create an Azure virtual network with optional subnets.
tags: [azure, module]
-->

# Azure virtual network

Create an Azure virtual network with optional subnets.

Requires Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.0.0.
The caller configures provider authentication and remote state. This module declares
provider requirements only and does not configure a provider or backend.
Configure the AzureRM `features` block and subscription ID in the caller.
Pin the selected provider version in the consuming root module lock file.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `settings` | `object` | Yes | — | Shared naming and region defaults; see below. |
| `name` | `string` | No | `null` | The resource name. |
| `resource_group_name` | `string` | Yes | — | The name of the existing resource group. |
| `location` | `string` | No | `null` | The Azure region in which to create the resource. |
| `tags` | `map(string)` | No | `{}` | Tags to assign to the resource. |
| `address_space` | `list(string)` | Yes | — | The address ranges for the virtual network. |
| `dns_servers` | `list(string)` | No | `[]` | Custom DNS servers. An empty list uses Azure DNS. |
| `subnets` | `map(object({ address_prefixes = list(string) }))` | No | `{}` | Subnets keyed by subnet name. |

## Outputs

- `id`: Id.
- `name`: Name.
- `location`: Location.
- `tags`: Tags.
- `address_space`: Address space.
- `subnet_ids`: Subnet resource IDs keyed by name.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/networking/vnet?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111" # Replace with your tenant ID.
  }
  name                = "vnet-example-dev-uksouth"
  resource_group_name = "rg-example-dev-uksouth"
  location            = "uksouth"
  address_space       = ["10.0.0.0/16"]
  subnets = {
    aks = { address_prefixes = ["10.0.0.0/22"] }
  }
}
```

Replace the source revision with a published tag or commit. Replace example resource
names and object IDs with your own values. Pass outputs from other units through
Terragrunt `dependency` blocks when composing these modules.

## Behavior and upgrade considerations

Subnet ranges must be contained in the virtual network and must not overlap. Network
security groups, routes, peering, and outbound connectivity are caller-managed. Changing
address ranges can disrupt connected resources.

## Shared solution settings

Pass the required `settings = module.solution_settings.settings` input. The module
accepts the full settings output and reads only the fields declared in its input
type. Pass tags separately with `tags = module.solution_settings.tags` where supported.

The default name is `${settings.name_prefix}vnet`, with no separator added.
A nonempty `name` overrides the generated name. Name resolution lives in
the top-level `locals` block, and the resource uses `local.name`.
`location` defaults to `settings.region_long`; an explicit nonempty location wins.

Generated names are not truncated or guaranteed unique. Review name changes in
the plan because they can replace existing resources.
