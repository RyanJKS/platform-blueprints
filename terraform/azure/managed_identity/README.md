<!-- Frontmatter
name: Azure managed identity
description: Create a user-assigned Azure managed identity with optional federated credentials.
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
| `settings` | `object` | Yes | — | Shared naming and region defaults; see below. |
| `name` | `string` | No | `null` | The resource name. |
| `resource_group_name` | `string` | Yes | — | The name of the existing resource group. |
| `location` | `string` | No | `null` | The Azure region in which to create the resource. |
| `tags` | `map(string)` | No | `{}` | Tags to assign to the resource. |
| `federated_identity_credentials` | `map(object)` | No | `{}` | Credentials with required issuer and subject, plus an optional audience. |

The optional `federated_identity_credentials` input is a map keyed by credential
name. It defaults to `{}`, which creates no federated credentials. See the
federation example below for its fields.

## Outputs

- `id`: Id.
- `name`: Name.
- `location`: Location.
- `tags`: Tags.
- `client_id`: Client id.
- `principal_id`: Principal id.
- `tenant_id`: Tenant id.
- `federated_identity_credential_ids`: Credential resource IDs keyed by credential name; empty when no credentials are configured.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/managed_identity?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111" # Replace with your tenant ID.
  }
  name                = "id-example-dev-uksouth"
  resource_group_name = "rg-example-dev-uksouth"
  location            = "uksouth"
}
```

Replace the source revision with a published tag or commit. Replace example resource
names and object IDs with your own values. Pass outputs from other units through
Terragrunt `dependency` blocks when composing these modules.

## Federated identity credentials

Each credential value has this type:

```hcl
object({
  issuer   = string
  subject  = string
  audience = optional(list(string), ["api://AzureADTokenExchange"])
})
```

For an AKS workload, add these inputs to the managed identity unit:

```hcl
dependency "aks" {
  config_path = "../aks"
}

inputs = {
  # Include the settings and resource_group_name inputs shown above.
  federated_identity_credentials = {
    payments-api = {
      issuer  = dependency.aks.outputs.oidc_issuer_url
      subject = "system:serviceaccount:payments:api"
    }
  }
}
```

The map key becomes the credential name. Names must satisfy Azure naming rules
and be unique within the identity. Issuer and subject must exactly match the
incoming token claims. Azure supports exactly one audience per credential.
Omitting `audience` uses `api://AzureADTokenExchange`.

Enable OIDC and workload identity on AKS. Annotate the Kubernetes service account
with `azure.workload.identity/client-id` set to this module's `client_id`, and label
the pod template with `azure.workload.identity/use: "true"`. Configure Kubernetes
resources and the identity's Azure role assignments separately. Avoid a circular
Terragrunt dependency if the AKS unit already depends on this identity; use a
separate workload identity unit that depends on the existing cluster.

For GitHub Actions, use `https://token.actions.githubusercontent.com` as the issuer
and the exact repository, branch, or environment subject required by the workflow.
Grant the workflow `id-token: write` and configure Azure login with the identity's
client ID, tenant ID, and subscription ID. Federated credentials allow token
exchange; they do not grant Azure resource permissions.

Removing a credential from the map deletes that trust relationship. Adding these
optional inputs does not change the existing identity resource address or outputs.

## Behavior and upgrade considerations

Role assignments are caller-managed. Optional federated credentials are managed
by this module through `federated_identity_credentials`. Use `id` when
attaching this identity to AKS and `principal_id` when assigning Azure roles. Replacing
the identity changes its principal and client IDs.

## Shared solution settings

Pass the required `settings = module.solution_settings.settings` input. The module
accepts the full settings output and reads only the fields declared in its input
type. Pass tags separately with `tags = module.solution_settings.tags` where supported.

The default name is `${settings.name_prefix}id`, with no separator added.
A nonempty `name` overrides the generated name. Name resolution lives in
the top-level `locals` block, and the resource uses `local.name`.
`location` defaults to `settings.region_long`; an explicit nonempty location wins.

Generated names are not truncated or guaranteed unique. Review name changes in
the plan because they can replace existing resources.
