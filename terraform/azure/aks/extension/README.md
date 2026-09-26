---
name: Azure AKS extension
description: Install an Azure-managed Kubernetes extension on an existing AKS cluster.
---

# AKS extension

Install an Azure-managed Kubernetes extension independently of the AKS cluster. Use one module instance per extension. Requires Terraform >= 1.3.0 and AzureRM >= 5.0.0. The caller configures providers and state.

## Inputs and outputs

- `settings` (required): Shared solution settings containing `name_prefix`.
- `cluster_id` (required): The AKS cluster resource ID.
- `extension` (required): Deployment settings described below.
- `configuration_protected_settings` (optional, default `{}`): Sensitive settings passed to the extension. Terraform still stores these values in state; protect the state backend.
- Output `id`: The extension resource ID.

| Extension setting | Default | Description |
| --- | --- | --- |
| `extension_type` | Required | Azure extension type, such as `microsoft.flux` or `microsoft.argocd`. |
| `name` | `null` | Defaults to `${settings.name_prefix}extension`. Use unique names for multiple extensions on the same cluster. |
| `release_train` | `"Stable"` | Release train supported by the chosen extension. |
| `release_namespace` | `null` | Optional Kubernetes namespace for the extension. |
| `version` | `null` | Optional pinned extension version. When set, the module omits `release_train` because AzureRM treats them as mutually exclusive. |
| `configuration_settings` | `{}` | Non-secret extension settings, passed through unchanged. |

The module does not inject extension-specific settings or validate extension-specific capacity requirements. Check the chosen extension's supported versions, release trains, identity, capacity, permissions, and connectivity requirements before deploying. Register `Microsoft.KubernetesConfiguration` in the subscription.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/aks/extension?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

dependency "cluster" {
  config_path = "../cluster"
}

inputs = {
  settings   = { name_prefix = "paymentsuksdev" }
  cluster_id = dependency.cluster.outputs.id
  extension = {
    name           = "paymentsuksdevflux"
    extension_type = "microsoft.flux"
  }
}
```

Deploy the cluster first. Pass the full solution settings output when available; this module reads only `name_prefix`.

## Argo CD example

Use the following `extension` value to retain the previous module's non-HA behavior:

```hcl
extension = {
  name              = "paymentsuksdevargocd"
  extension_type    = "microsoft.argocd"
  release_train     = "preview"
  release_namespace = "argocd"
  configuration_settings = {
    deployWithHighAvailability = "false"
    "redis-ha.enabled"        = "false"
    namespaceInstall          = "false"
  }
}
```

For HA, set both HA settings to `"true"` and provision the capacity required by the [Microsoft Argo CD tutorial](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-argocd), currently at least four nodes. The generic module does not enforce this requirement.

## Migration from argocd_extension

Change the source path to `azure/aks/extension` and keep the existing module call name and state. Rename input `argocd` to `extension`, add `extension_type = "microsoft.argocd"`, and rename `namespace` to `release_namespace`. Set `release_train = "preview"` explicitly to preserve the previous default. Preserve any pinned `version` and existing configuration settings.

Remove `minimum_node_count`. Replace `high_availability` with string values for both `deployWithHighAvailability` and `redis-ha.enabled` in `configuration_settings`. Replace `namespace_install` with the string setting `namespaceInstall`. Preserve the effective values from the old module, which overrode these map entries with its typed inputs.

Set `extension.name` to the existing Azure extension name: the generated suffix changes from `argocd` to `extension`. Preserve the existing namespace explicitly, since the new default is `null`.

An included `moved` block migrates the resource address from `azurerm_kubernetes_cluster_extension.argocd` to `azurerm_kubernetes_cluster_extension.extension` within the same module instance. If you rename the module call, also add a root-level `moved` block for that module. See [AKS migration guidance](../README.md#migration) for extensions previously managed in the cluster module or a separate state. Review the plan for replacements before applying.
