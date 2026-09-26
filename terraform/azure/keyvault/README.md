<!-- Frontmatter
name: Azure Key Vault
description: Create an Azure Key Vault with RBAC authorization and purge protection.
tags: [azure, module]
-->

# Azure Key Vault

Create an Azure Key Vault with RBAC authorization and purge protection.

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
| `tenant_id` | `string` | No | `null` | The Microsoft Entra tenant ID. |
| `sku_name` | `string` | No | `"standard"` | The Key Vault SKU. |
| `soft_delete_retention_days` | `number` | No | `90` | The retention period for deleted vaults and objects. |
| `purge_protection_enabled` | `bool` | No | `true` | Whether to enable irreversible purge protection. |
| `public_network_access_enabled` | `bool` | No | `false` | Whether to allow access through the public endpoint. |

## Outputs

- `id`: Id.
- `name`: Name.
- `location`: Location.
- `tags`: Tags.
- `tenant_id`: Tenant id.
- `vault_uri`: Vault uri.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/keyvault?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111" # Replace with your tenant ID.
  }
  name                = "kv-example-dev-001"
  resource_group_name = "rg-example-dev-uksouth"
  location            = "uksouth"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
}
```

Replace the source revision with a published tag or commit. Replace example resource
names and object IDs with your own values. Pass outputs from other units through
Terragrunt `dependency` blocks when composing these modules.

## Behavior and upgrade considerations

Public network access is disabled by default. Create a private endpoint and private DNS
outside this module before accessing secrets, or explicitly enable public access. Assign
Key Vault data-plane roles separately; this module does not grant access or manage
secrets. Vault names must be globally unique. Purge protection cannot be disabled once
enabled, and retention cannot be changed after creation. AzureRM 5 uses
`rbac_authorization_enabled`; legacy access policies are not configured.

## Shared solution settings

Pass the required `settings = module.solution_settings.settings` input. The module
accepts the full settings output and reads only the fields declared in its input
type. Pass tags separately with `tags = module.solution_settings.tags` where supported.

The default name is `${settings.name_prefix}akv`, with no separator added.
A nonempty `name` overrides the generated name. Name resolution lives in
the top-level `locals` block, and the resource uses `local.name`.
`location` defaults to `settings.region_long`; an explicit nonempty location wins.
`tenant_id` defaults to `settings.tenant_id`; an explicit nonempty tenant ID wins.

Generated names are not truncated or guaranteed unique. Review name changes in
the plan because they can replace existing resources.
