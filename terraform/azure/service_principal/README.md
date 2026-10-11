<!-- Frontmatter
name: Microsoft Entra service principal
description: Create a service principal with web sign-in callbacks, federated identity credentials, and optional credentials stored in Azure Key Vault.
tags: [azure, identity, module]
-->

# Microsoft Entra service principal

Creates a Microsoft Entra application and its service principal. Optional web redirect URIs support sign-in callbacks, and federated identity credentials support workload token exchange. Set `create_secret = true` to create a service principal password and store both credentials in an existing Azure Key Vault:

- `<name>-client-id` contains the application (client) ID.
- `<name>-client-secret` contains the generated password.

When `create_secret` is false (the default), the module creates neither a password nor Key Vault secrets. Switching it from true to false removes the managed password and both secrets.

Requires Terraform >= 1.3.0, `hashicorp/azuread` >= 3.0.0 and < 4.0.0, and `hashicorp/azurerm` >= 5.0.0. The caller configures provider authentication and remote state. This module declares provider requirements only.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | Required | Application and service principal display name. |
| `owners` | `set(string)` | `[]` | Owner object IDs for the application and service principal. |
| `redirect_uris` | `set(string)` | `[]` | Web sign-in callback URLs on the application. |
| `federated_identity_credentials` | `map(object)` | `{}` | Application federated credentials keyed by credential name; see the schema below. |
| `create_secret` | `bool` | `false` | Create a password and store the client ID and password in Key Vault. |
| `key_vault_id` | `string` | `null` | Existing Key Vault resource ID; required when `create_secret` is true. |

When creating secrets, `name` must contain only letters, numbers, and hyphens and be at most 113 characters. This preserves the requested naming convention and keeps both secret names within Key Vault's 127-character limit.

Each `federated_identity_credentials` value has this schema:

```hcl
object({
  issuer      = string
  subject     = string
  audiences   = optional(list(string), ["api://AzureADTokenExchange"])
  description = optional(string)
})
```

Each credential needs a nonempty name, issuer, and subject, and exactly one nonempty audience. The issuer and subject must match the external token claims exactly. Federated credentials are attached to the application behind the service principal. They work independently of `create_secret` and `redirect_uris`.

## Outputs

| Name | Description |
| --- | --- |
| `id` | Service principal resource ID. |
| `object_id` | Service principal object ID for Azure role assignments. |
| `client_id` | Application (client) ID. |
| `display_name` | Service principal display name. |
| `federated_identity_credential_ids` | Federated credential resource IDs keyed by credential name; empty when none are configured. |
| `client_id_secret_id` | Client ID secret ID, or null when secrets are disabled. |
| `client_secret_secret_id` | Client secret ID, or null when secrets are disabled. |

The password is not exposed as an output. Terraform still stores the password and Key Vault secret values in state; protect the state backend and restrict access.

## Terraform usage

```hcl
module "service_principal" {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/service_principal?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"

  name          = "platform-deploy"
  create_secret = true
  key_vault_id  = module.keyvault.id
}
```

For a service principal without credentials, supply only `name`.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/service_principal?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

dependency "keyvault" {
  config_path = "../keyvault"
}

inputs = {
  name          = "platform-deploy"
  create_secret = true
  key_vault_id  = dependency.keyvault.outputs.id
}
```

## Argo CD sign-in and workload federation

For direct Argo CD OIDC sign-in, register the `/auth/callback` URL. When using Argo CD's bundled Dex with its Microsoft connector, register `/api/dex/callback` instead. Use the URL matching your Argo CD configuration.

```hcl
module "argocd_identity" {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/service_principal?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"

  name          = "argocd-sso"
  redirect_uris = ["https://argocd.example.com/auth/callback"]
  create_secret = true
  key_vault_id  = module.keyvault.id
}
```

Configure Argo CD's OIDC issuer, client ID, and client secret separately. The client ID and password are available in the supplied vault under `argocd-sso-client-id` and `argocd-sso-client-secret`. Group claims and Argo CD RBAC require separate configuration.

For workload federation, supply the external issuer and service account subject:

```hcl
federated_identity_credentials = {
  "argocd-controller" = {
    issuer      = "https://YOUR_CLUSTER_OIDC_ISSUER/"
    subject     = "system:serviceaccount:argocd:argocd-application-controller"
    description = "Argo CD controller workload identity"
  }
}
```

Workload federation exchanges an external workload token for an Azure token. It configures authentication for the workload; Azure role assignments, Kubernetes workload identity configuration, and human SSO remain separate setup steps.

## Permissions and credential lifecycle

The caller needs Microsoft Graph permissions to create applications, service principals, and passwords. When secrets are enabled, the AzureRM identity also needs Key Vault secret read and write permissions and network access to the vault. For an RBAC-enabled vault, assign an appropriate role such as Key Vault Secrets Officer before applying this module.

The password uses the AzureAD provider's default expiration. This module does not automatically rotate expiring credentials. Key Vault soft delete and purge protection also apply when secrets are removed; the caller controls the AzureRM provider's Key Vault recovery and purge settings.

## Validation

Mocked tests require Terraform >= 1.7.0 and do not deploy Azure resources:

```sh
terraform -chdir=terraform/azure/service_principal init -backend=false
terraform -chdir=terraform/azure/service_principal validate
terraform -chdir=terraform/azure/service_principal test
```
