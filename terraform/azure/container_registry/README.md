<!-- Frontmatter
name: Azure Container Registry
description: Create a container registry with access controls, managed identity, and optional Premium networking and replication.
tags: [azure, containers, module]
-->

# Azure Container Registry

Creates one Azure Container Registry in an existing resource group. Requires
Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.7.0 and < 6.0.0.

The caller configures the AzureRM provider, authentication, subscription, and
remote state. This module declares provider requirements only.

The registry always uses `settings.region_long` for its location. Pass
`settings = module.solution_settings.settings` and, when needed,
`tags = module.solution_settings.tags`.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `settings` | `object({ name_prefix = string, region_long = string })` | Yes | None | Shared naming values and registry region. |
| `resource_group_name` | `string` | Yes | None | Existing resource group name. |
| `name` | `string` | No | `null` | Overrides the generated registry name. |
| `sku` | `string` | No | `"Basic"` | `Basic`, `Standard`, or `Premium`. |
| `admin_enabled` | `bool` | No | `false` | Enables the shared admin account. |
| `anonymous_pull_enabled` | `bool` | No | `false` | Allows unauthenticated pulls; requires Standard or Premium. |
| `public_network_access_enabled` | `bool` | No | `true` | Enables the public endpoint. |
| `network_rule_bypass_option` | `string` | No | `"AzureServices"` | Trusted service bypass: `AzureServices` or `None`. |
| `network_rule_set` | `object` | No | `null` | Premium firewall rules; see below. |
| `data_endpoint_enabled` | `bool` | No | `false` | Premium dedicated data endpoints. |
| `export_policy_enabled` | `bool` | No | `true` | Disabling exports requires Premium and disabled public access. |
| `zone_redundancy_enabled` | `bool` | No | `false` | Premium zone redundancy in a supported region. |
| `identity` | `object` | No | `null` | Registry managed identity; see below. |
| `georeplications` | `list(object)` | No | `[]` | Premium replicas; see below. |
| `tags` | `map(string)` | No | `{}` | Registry tags. |

The generated name is the lowercase `settings.name_prefix` with non-alphanumeric
characters removed, followed by `acr`. Names must contain 5 to 50 letters or
digits and be globally unique. Generated names are not truncated or guaranteed
unique; supply `name` when necessary.

`network_rule_set` accepts `default_action` (`Allow` or `Deny`, default `Deny`)
and `ip_ranges` (a set of IPv4 CIDR ranges, default empty). Every IP rule allows
access from its range. Public access must be enabled for public IP rules to
provide connectivity.

`identity` accepts `type` (`SystemAssigned`, `UserAssigned`, or
`SystemAssigned, UserAssigned`) and `identity_ids` (a set of user-assigned Azure
resource IDs). IDs are required for either type containing `UserAssigned` and
must be empty for `SystemAssigned`.

Each `georeplications` entry accepts `location`, `zone_redundancy_enabled`
(default `false`), `global_endpoint_routing_enabled` (default `true`), and `tags`
(default `{}`). Locations must be unique and differ from `settings.region_long`.
Replica tags do not inherit registry tags.

## Outputs

| Name | Description |
| --- | --- |
| `id` | Azure resource ID, suitable as an RBAC scope. |
| `name` | Registry name. |
| `location` | Registry region from shared settings. |
| `login_server` | Hostname used to tag, push, and pull images. |
| `data_endpoint_host_names` | Dedicated data endpoint hostnames when enabled. |
| `identity` | Registry identity object, or `null` if not configured. |
| `tags` | Registry tags. |
| `admin_username` | Sensitive admin username, or `null` when disabled. |
| `admin_password` | Sensitive admin password, or `null` when disabled. |

## Terraform usage

```hcl
module "container_registry" {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/container_registry?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"

  settings            = module.solution_settings.settings
  resource_group_name = module.resource_group.name
  tags                = module.solution_settings.tags
}
```

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/container_registry?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

dependency "solution_settings" {
  config_path = "../solution_settings"
}

dependency "resource_group" {
  config_path = "../resource_group"
}

inputs = {
  settings            = dependency.solution_settings.outputs.settings
  resource_group_name = dependency.resource_group.outputs.name
  tags                = dependency.solution_settings.outputs.tags
  sku                 = "Premium"
  network_rule_set = {
    default_action = "Deny"
    ip_ranges      = ["203.0.113.0/24"]
  }
  georeplications = [{ location = "westeurope" }]
}
```

Replace the source revision with a published tag or commit containing this module.

## Behavior and upgrade considerations

Authentication is required by default. Assign `AcrPull` to the AKS kubelet
identity or another client identity using the registry `id` as the scope.
Assign `AcrPush` to identities that publish images. The registry's own managed
identity does not grant clients access to images. Role assignments, private
endpoints, private DNS, registry tasks, and customer-managed encryption keys
are managed separately.

Private endpoints require Premium. Disabling public access requires separate
private connectivity for clients. Anonymous pull makes images accessible without
credentials. Admin credentials are shared credentials and are stored in Terraform
state when enabled; protect state access.

Geo-replication and zone redundancy depend on Azure region support. Changing the
registry name, region, or resource group requires replacement. Some zone
redundancy changes also require replacement. Review the plan and pin the provider
version in the consuming root module's lock file.

## Validation

With Terraform >= 1.7.0, run:

```sh
terraform init -backend=false
terraform validate
terraform test
```

Tests use a mocked AzureRM provider and do not require Azure credentials or deploy
Azure resources.
