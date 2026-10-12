<!-- Frontmatter
name: Azure Log Analytics workspace
description: Create a Log Analytics workspace with retention, ingestion limits, and access controls.
tags: [azure, monitoring, module]
-->

# Azure Log Analytics workspace

Creates one Log Analytics workspace in an existing resource group. Requires
Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.7.0 and < 6.0.0.

The caller configures the AzureRM provider, including its `features` block,
subscription, authentication, and remote state. This module declares provider
requirements only; it does not configure a provider or backend.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `settings` | `object({ name_prefix = string, region_long = string })` | Yes | — | Shared naming and region defaults. |
| `resource_group_name` | `string` | Yes | — | Existing resource group name. |
| `name` | `string` | No | `null` | Overrides `${settings.name_prefix}law`. |
| `location` | `string` | No | `null` | Overrides `settings.region_long`. |
| `sku` | `string` | No | `"PerGB2018"` | Pricing tier: `PerGB2018`, `CapacityReservation`, `LACluster`, or a supported legacy tier (`PerNode`, `Premium`, `Standalone`, `Standard`, `Unlimited`). |
| `retention_in_days` | `number` | No | `30` | Whole number from 30 to 730. Table settings can override workspace retention. |
| `daily_quota_gb` | `number` | No | `-1` | Positive ingestion cap in GB; `-1` means unlimited. |
| `reservation_capacity_in_gb_per_day` | `number` | No | `null` | Required only for `CapacityReservation`: 50, 100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000, or 50000. |
| `local_authentication_enabled` | `bool` | No | `false` | Enables shared-key authentication alongside Microsoft Entra authentication. |
| `allow_resource_only_permissions` | `bool` | No | `true` | Allows resource-context queries based on permissions on the source resource. |
| `internet_ingestion_access_type` | `string` | No | `"Enabled"` | Public ingestion access: `Enabled`, `Disabled`, or `SecuredByPerimeter`. |
| `internet_query_access_type` | `string` | No | `"Enabled"` | Public query access: `Enabled`, `Disabled`, or `SecuredByPerimeter`. |
| `tags` | `map(string)` | No | `{}` | Workspace tags. |

Pass `settings = module.solution_settings.settings` and, when needed,
`tags = module.solution_settings.tags`. Explicit nonempty name and location
inputs override shared settings. Generated names are not truncated or guaranteed
unique. Names must contain 4 to 63 letters, digits, or hyphens and must start and
end with a letter or digit.

## Outputs

| Name | Description |
| --- | --- |
| `id` | Azure resource ID. Use this for AKS `oms_agent.log_analytics_workspace_id`. |
| `workspace_id` | Workspace customer GUID, distinct from the Azure resource ID. |
| `name` | Workspace name. |
| `location` | Workspace region. |
| `tags` | Workspace tags. |
| `primary_shared_key` | Sensitive primary shared key; usable only with local authentication enabled. |
| `secondary_shared_key` | Sensitive secondary shared key; usable only with local authentication enabled. |

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/log_analytics?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
  resource_group_name = "rg-payments-dev-uksouth"
  retention_in_days   = 90
  daily_quota_gb      = 10
  tags               = { environment = "dev" }
}
```

Replace the source revision with a published tag or commit containing this module.
For AKS, pass `dependency.log_analytics.outputs.id` to
`oms_agent.log_analytics_workspace_id` and keep
`msi_auth_for_monitoring_enabled = true` when shared-key authentication is disabled.

## Behavior and upgrade considerations

Public ingestion and query access are enabled by default; authentication is still
required. With `Disabled`, provision Azure Monitor Private Link connectivity
separately. `SecuredByPerimeter` requires an enforced network security perimeter
association. This module does not create private endpoints, perimeter associations,
role assignments, data collection rules, table resources, or workspace solutions.

Legacy pricing tiers may be unavailable for new workspaces. `LACluster` requires a
separately managed Log Analytics cluster link. Capacity reservations create a
31-day commitment before the tier can be lowered. A daily cap can interrupt log
collection and is not a guaranteed spending limit.

Changing the workspace name, location, or resource group requires replacement.
Some SKU changes also require replacement. Review the plan before changing an
existing workspace. Pin the provider version in the consuming root module lock
file. Sensitive outputs are stored in Terraform state; protect state access.

## Validation

With Terraform >= 1.7.0, run:

```sh
terraform init -backend=false
terraform validate
terraform test
```

Tests use a mocked AzureRM provider and do not require Azure credentials or deploy
Azure resources.
