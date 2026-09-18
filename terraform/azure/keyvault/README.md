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
| `name` | `string` | Yes | — | The resource name. |
| `resource_group_name` | `string` | Yes | — | The name of the existing resource group. |
| `location` | `string` | Yes | — | The Azure region in which to create the resource. |
| `tags` | `map(string)` | No | `{}` | Tags to assign to the resource. |
| `tenant_id` | `string` | Yes | — | The Microsoft Entra tenant ID. |
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
