<!-- Frontmatter
name: Azure managed identity
description: Create a user-assigned Azure managed identity.
tags: [azure, module]
-->

# Azure managed identity

Create a user-assigned Azure managed identity.

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

## Outputs

- `id`: Id.
- `name`: Name.
- `location`: Location.
- `tags`: Tags.
- `client_id`: Client id.
- `principal_id`: Principal id.
- `tenant_id`: Tenant id.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/managed_identity?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  name                = "id-example-dev-uksouth"
  resource_group_name = "rg-example-dev-uksouth"
  location            = "uksouth"
}
```

Replace the source revision with a published tag or commit. Replace example resource
names and object IDs with your own values. Pass outputs from other units through
Terragrunt `dependency` blocks when composing these modules.

## Behavior and upgrade considerations

Role assignments and federated identity credentials are caller-managed. Use `id` when
attaching this identity to AKS and `principal_id` when assigning Azure roles. Replacing
the identity changes its principal and client IDs.
