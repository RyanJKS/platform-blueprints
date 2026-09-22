<!-- Frontmatter
name: Azure AKS Argo CD extension
description: Install the Azure-managed Argo CD extension on an existing AKS cluster.
tags: [azure, aks, module]
-->

# AKS Argo CD extension

Install Argo CD independently of the AKS cluster. Requires Terraform >= 1.3.0 and AzureRM >= 5.0.0. The caller configures providers and state.

## Inputs and outputs

- `cluster_id` (required string): Existing managed-identity AKS cluster resource ID.
- `minimum_node_count` (required positive integer): Actual cluster node count, or autoscaling minimum. Pass the cluster module output so HA validation follows cluster settings.
- `argocd` (optional object, default `{}`): Extension settings below. This module always creates the extension; omit the module to disable it.
- Output `id`: Extension resource ID.

The `argocd` object supports these defaults:

| Setting | Default | Description |
| --- | --- | --- |
| `name` | `null` | Name override; defaults to `${settings.name_prefix}argocd`. |
| `release_train` | `"preview"` | Extension release train. |
| `version` | `null` | Optional extension version. |
| `namespace` | `"argocd"` | Namespace in which the extension installs Argo CD. |
| `namespace_install` | `false` | Extension namespace installation setting. |
| `high_availability` | `false` | Enable Argo CD HA. |
| `configuration_settings` | `{}` | Additional non-secret extension settings. |

The module supplies `deployWithHighAvailability` and `namespaceInstall` from the
typed settings. It also supplies `redis-ha.enabled`, which the current Microsoft
tutorial uses to disable default Redis HA. These three reserved settings override
entries with the same names in `configuration_settings` so the HA validation
cannot be bypassed accidentally. Do not put credentials in this map.

The [Microsoft Argo CD tutorial](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-argocd)
currently requires four nodes for the default HA configuration. With HA enabled,
`minimum_node_count` must be at least four. The module cannot guarantee node placement, resource capacity,
or regional extension availability; review those before deploying. HA is disabled
by default, including Redis HA, so the three-node example below remains valid.

AKS must use a managed identity for the extension. This module defaults to a
system-assigned identity; supplying `identity_ids` selects user-assigned identity.
Register `Microsoft.KubernetesConfiguration` and grant the deploying identity the
required extension permissions. Private clusters still need outbound connectivity
to the extension's Azure endpoints and container registry.


## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/aks/argocd_extension?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

dependency "cluster" {
  config_path = "../cluster"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111" # Replace with your tenant ID.
  }
  cluster_id         = dependency.cluster.outputs.id
  minimum_node_count = dependency.cluster.outputs.minimum_node_count
  argocd = {
    high_availability = false
  }
}
```

Deploy the cluster first. The example assumes sibling Terragrunt units named `cluster` and `argocd_extension`. The capacity input validates declared configuration, not live node availability.

See [migration guidance](../README.md#migration) before splitting an existing deployment.

## Shared solution settings

Pass the required `settings = module.solution_settings.settings` input. The module
accepts the full settings output and reads only the fields declared in its input
type. Pass tags separately with `tags = module.solution_settings.tags` where supported.

The default name is `${settings.name_prefix}argocd`, with no separator added.
A nonempty `argocd.name` overrides the generated name. Name resolution lives in
the top-level `locals` block, and the resource uses `local.name`.

Generated names are not truncated or guaranteed unique. Review name changes in
the plan because they can replace existing resources.
