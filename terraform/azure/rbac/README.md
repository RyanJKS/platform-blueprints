<!-- Frontmatter
name: Azure RBAC assignment
description: Assign an Azure role to a user, group, service principal, or managed identity.
tags: [azure, rbac, module]
-->

# Azure RBAC assignment

Creates one Azure role assignment at a resource, resource group, subscription, or
management group scope. Use multiple module instances for multiple assignments.

Requires Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.0.0. The caller configures
the AzureRM `features` block, subscription ID, authentication, and remote state.
This module does not configure a provider or backend. Pin the selected provider
version in the consuming root module lock file.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `scope` | `string` | Yes | — | Full Azure resource ID at which to assign the role. |
| `principal_id` | `string` | Yes | — | Microsoft Entra object ID of the principal. |
| `type` | `string` | Yes | — | Principal type: `User`, `Group`, or `ServicePrincipal`. |
| `role_definition_name` | `string` | One role selector | `null` | Built-in role name, such as `Reader`, `Contributor`, or `Key Vault Secrets User`. |
| `role_definition_id` | `string` | One role selector | `null` | Full scoped role definition resource ID, including for custom roles. |
| `name` | `string` | No | `null` | Optional assignment UUID; generated when omitted. |
| `description` | `string` | No | `null` | Assignment description. |
| `condition` | `string` | No | `null` | Azure ABAC condition; automatically uses condition version `2.0`. |
| `skip_service_principal_aad_check` | `bool` | No | `false` | Skip the Entra existence check for a newly created service principal or managed identity. |

Set exactly one of `role_definition_name` and `role_definition_id`. `type` describes
the principal, not the role:

| Principal | `type` | `principal_id` source |
| --- | --- | --- |
| User | `User` | Entra user object ID. |
| Security group | `Group` | Group `object_id`, including the `ad_group` module output. |
| Application service principal | `ServicePrincipal` | Enterprise application service principal object ID, not application/client ID. |
| Managed identity | `ServicePrincipal` | Identity `principal_id`, including the `managed_identity` module output. |

## Outputs

- `id`: Role assignment resource ID.
- `name`: Role assignment UUID.
- `scope`: Assignment scope.
- `principal_id`: Assigned principal object ID.
- `type`: Assigned principal type.
- `role_definition_id`: Resolved role definition resource ID.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/rbac?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

dependency "group" {
  config_path = "../ad-group"
}

dependency "resource_group" {
  config_path = "../resource-group"
}

inputs = {
  scope                = dependency.resource_group.outputs.id
  principal_id         = dependency.group.outputs.object_id
  type                 = "Group"
  role_definition_name = "Reader"
  description          = "Read access for the platform group."
}
```

Replace the source revision with a published tag or commit and dependency paths
with your own unit paths. For a managed identity, set `type = "ServicePrincipal"`
and use its `principal_id`. Set `skip_service_principal_aad_check = true` only when
needed for a newly created principal that has not replicated in Entra yet.

## Behavior and upgrade considerations

The deploying identity needs permission to create role assignments at the chosen
scope. This module grants Azure RBAC permissions; it does not create Entra
directory roles, Kubernetes RoleBindings, custom role definitions, or PIM-eligible
assignments. An Azure role assignment does not grant Microsoft Graph permissions.

Select the narrowest scope and role needed. Role availability and supported ABAC
conditions depend on the Azure service and selected role. Azure validates
condition semantics; mocked tests only verify how this module passes conditions.

Changing the principal, role, or scope can replace the assignment. Import existing
assignments before managing them to avoid duplicate-assignment conflicts. Azure
authorization changes can take time to propagate.

## Tests

With Terraform >= 1.7.0, run `terraform init -backend=false`, `terraform validate`,
and `terraform test` from this directory. Tests cover all three principal types,
custom role IDs, ABAC settings, and invalid input combinations. They use a mocked
provider and do not grant Azure permissions. The PR workflow discovers this
module automatically.
