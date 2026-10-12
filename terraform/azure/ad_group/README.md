<!-- Frontmatter
name: Microsoft Entra security groups
description: Create Microsoft Entra ID security groups from a map with per-group owners and members.
tags: [azure, module]
-->

# Microsoft Entra security groups

Creates Microsoft Entra ID security groups from a map keyed by group display name.
Each value configures that group's description, owners, members, and duplicate-name
prevention. An empty value (`{}`) uses the defaults; an empty map creates no groups.

Requires Terraform >= 1.3.0 and `hashicorp/azuread` >= 3.0.0 and < 4.0.0. The caller
configures provider authentication and remote state. This module declares provider
requirements only; it does not configure a provider or backend.

## Inputs

`groups` is a required, non-null map with this type:

```hcl
map(object({
  description             = optional(string)
  owners                  = optional(set(string), [])
  members                 = optional(set(string), [])
  prevent_duplicate_names = optional(bool, true)
}))
```

Each map key is the group's display name and Terraform instance key. Keys must
contain at least one non-whitespace character. Each value accepts:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `description` | `string` | `null` | Group description. |
| `owners` | `set(string)` | `[]` | Object IDs of group owners. |
| `members` | `set(string)` | `[]` | Object IDs of direct group members. |
| `prevent_duplicate_names` | `bool` | `true` | Reject an existing group with the same display name. |

All groups are security-enabled and mail-disabled.

## Outputs

All outputs are maps keyed by group display name.

| Name | Description |
| --- | --- |
| `id` | Group resource IDs. |
| `object_id` | Group object IDs for role assignments and AKS administrator groups. |
| `display_name` | Group display names. |
| `groups` | Objects containing `id`, `object_id`, and `display_name` for each group. |

For example, select `dependency.groups.outputs.object_id["aks-example-admins"]`
for a particular group's object ID.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/ad_group?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  groups = {
    "aks-example-admins" = {
      description = "Administrators for the example AKS cluster"
      owners      = ["00000000-0000-0000-0000-000000000000"]
      members     = ["11111111-1111-1111-1111-111111111111"]
    }
    "platform-reader" = {
      description = "Read access to platform resources"
      owners      = ["00000000-0000-0000-0000-000000000000"]
    }
    "application-users" = {}
  }
}
```

Replace the source revision with a published tag or commit. Replace example object
IDs with your own values. Pass outputs to other units through Terragrunt
`dependency` blocks when composing modules.

## Behavior and permissions

Microsoft Entra groups use Microsoft Graph through the `azuread` provider.
Configure AzureAD authentication in the caller. The caller needs permissions to
create groups and manage the supplied owners and members, such as
`Group.ReadWrite.All` and the required directory-read permissions.

Supply object IDs, not email addresses or application client IDs. The module
manages each group's complete direct membership; do not combine it with separate
membership resources for the same group.

## Migration from the single-group module

This change replaces the top-level `display_name`, `description`, `owners`,
`members`, and `prevent_duplicate_names` inputs with `groups`. Move the previous
attributes into a value keyed by the existing display name. The `id`,
`object_id`, and `display_name` outputs now return maps; update consumers to select
the relevant group key.

The resource address changes from `azuread_group.this` to
`azuread_group.this["<existing-display-name>"]`. Move the existing state address
before applying to preserve the existing group. For a Terraform caller using
`module "ad_group"`, add this block to the consuming root module:

```hcl
moved {
  from = module.ad_group.azuread_group.this
  to   = module.ad_group.azuread_group.this["aks-example-admins"]
}
```

Replace the module label and key with the actual values. For a Terragrunt unit
using this module directly, migrate its state from the unit directory:

```sh
terragrunt state mv 'azuread_group.this' 'azuread_group.this["aks-example-admins"]'
```

Use the existing group's exact display name as the key and review the next plan.
Because map keys identify instances, renaming a key without a state migration
plans deletion of the old group and creation of a new group.

## Validation

With Terraform >= 1.7.0, run:

```sh
terraform init -backend=false
terraform validate
terraform test
```

Tests use a mocked AzureAD provider and do not require Azure credentials or create
directory groups.
