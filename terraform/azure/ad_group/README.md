<!-- Frontmatter
name: Microsoft Entra security group
description: Create a Microsoft Entra ID security group with optional owners and members.
tags: [azure, module]
-->

# Microsoft Entra security group

Create a Microsoft Entra ID security group with optional owners and members.

Requires Terraform >= 1.3.0 and `hashicorp/azuread` >= 3.0.0 < 4.0.0.
The caller configures provider authentication and remote state. This module declares
provider requirements only and does not configure a provider or backend.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `display_name` | `string` | Yes | — | The display name of the security group. |
| `description` | `string` | No | `null` | The description of the security group. |
| `owners` | `set(string)` | No | `[]` | Object IDs of group owners. |
| `members` | `set(string)` | No | `[]` | Object IDs of direct group members. |
| `prevent_duplicate_names` | `bool` | No | `true` | Whether to reject an existing group with the same display name. |

## Outputs

- `id`: Id.
- `object_id`: Group object ID for role assignments.
- `display_name`: Display name.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/ad_group?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  display_name = "aks-example-admins"
  description  = "Administrators for the example AKS cluster"
  owners       = ["00000000-0000-0000-0000-000000000000"]
  members      = ["11111111-1111-1111-1111-111111111111"]
}
```

Replace the source revision with a published tag or commit. Replace example resource
names and object IDs with your own values. Pass outputs from other units through
Terragrunt `dependency` blocks when composing these modules.

## Behavior and upgrade considerations

Microsoft Entra groups use Microsoft Graph and the `azuread` provider, not AzureRM.
Configure AzureAD authentication in the caller. The caller needs permissions to create
groups and manage the supplied owners and members (for example, Group.ReadWrite.All with
the required directory-read permissions). Supply object IDs, not email addresses or
application client IDs. The module manages the complete direct membership; do not
combine it with separate membership resources. Use `object_id` for AKS administrator
groups and Azure role assignments.
