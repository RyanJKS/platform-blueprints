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
| `name` | `string` | Yes | — | The resource name. |
| `resource_group_name` | `string` | Yes | — | The name of the existing resource group. |
| `location` | `string` | Yes | — | The Azure region in which to create the resource. |
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
