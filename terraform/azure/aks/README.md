<!-- Frontmatter
name: Azure Kubernetes Service
description: Create an AKS cluster with a managed identity, a configurable system node pool,
and optional Argo CD, managed Prometheus, and application routing addons.
tags: [azure, module]
-->

# Azure Kubernetes Service

Create an AKS cluster with a managed identity, a configurable system node pool,
and optional Argo CD, managed Prometheus, and application routing addons.

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
| `dns_prefix` | `string` | Yes | — | The DNS prefix for the AKS cluster. |
| `kubernetes_version` | `string` | No | `null` | The Kubernetes version. Null uses the regional Azure default. |
| `node_pool_name` | `string` | No | `"system"` | The name of the default Linux node pool. |
| `node_count` | `number` | No | `2` | The number of nodes when autoscaling is disabled. |
| `vm_size` | `string` | No | `"Standard_D2s_v5"` | The virtual machine size for system nodes. |
| `vnet_subnet_id` | `string` | No | `null` | An existing subnet ID for the nodes. Null lets AKS manage networking. |
| `identity_ids` | `set(string)` | No | `[]` | User-assigned identity resource IDs. An empty set uses a system-assigned identity. |
| `admin_group_object_ids` | `set(string)` | No | `[]` | Microsoft Entra group object IDs for cluster administrators. |
| `private_cluster_enabled` | `bool` | No | `true` | Whether to create a private API server endpoint. |
| `oidc_issuer_enabled` | `bool` | No | `true` | Whether to enable the OIDC issuer. |
| `workload_identity_enabled` | `bool` | No | `true` | Whether to enable workload identity. Requires the OIDC issuer. |
| `sku_tier` | `string` | No | `"Free"` | The AKS pricing tier. |

| `auto_scaling_enabled` | `bool` | No | `false` | Enable the cluster autoscaler for the default pool. |
| `min_count` | `number` | No | `3` | Minimum nodes when autoscaling is enabled. |
| `max_count` | `number` | No | `5` | Maximum nodes when autoscaling is enabled. |
| `max_pods` | `number` | No | `null` | Pods per node; null uses the AKS default. |
| `node_public_ip_enabled` | `bool` | No | `false` | Assign public IP addresses to nodes. |
| `temporary_name_for_rotation` | `string` | No | `"rotatingpool"` | Temporary node pool name during rotation. |
| `zones` | `list(string)` | No | `[]` | Availability zones for the default pool. |
| `os_disk_size_gb` | `number` | No | `null` | Node OS disk size; null uses the AKS default. |
| `local_account_disabled` | `bool` | No | `null` | Null disables local accounts when Entra integration is enabled. |
| `tenant_id` | `string` | No | `null` | Entra tenant ID; also enables integration without administrator groups. |
| `azure_rbac_enabled` | `bool` | No | `true` | Use Azure RBAC for Entra integration. |
| `monitor_metrics` | `object` | No | `null` | Managed Prometheus settings, described below. |
| `web_app_routing` | `object` | No | `null` | Application routing settings, described below. |
| `argocd` | `object` | No | `null` | Argo CD settings, described below. |

## Outputs

- `id`: Id.
- `name`: Name.
- `location`: Location.
- `tags`: Tags.
- `node_resource_group`: Node resource group.
- `oidc_issuer_url`: Oidc issuer url.
- `identity`: Identity.
- `kubelet_identity`: Kubelet identity.

- `argocd_extension_id`: Argo CD extension ID, or null when disabled.
- `web_app_routing_identity`: Application routing identity for DNS role assignments.
- `kube_config_raw`: Sensitive cluster kubeconfig.
- `kube_admin_config_raw`: Sensitive administrator kubeconfig, available when Entra
  integration and local accounts are enabled.

## Optional addon settings

Set `monitor_metrics = {}` to enable managed Prometheus with Azure defaults. The
optional `annotations_allowed` and `labels_allowed` strings configure scrape
metadata. Azure Monitor workspace associations, data collection rules, and role
assignments remain caller-managed.

Set `web_app_routing = {}` to enable application routing. `dns_zone_ids` defaults
to an empty list. `default_nginx_controller` defaults to `"External"` and also
accepts `"Internal"`, `"None"`, or `"AnnotationControlled"`. An external controller
can expose a public load balancer even when the cluster API is private. Grant the
returned routing identity the required roles on the configured DNS zones.

Set `argocd = {}` to install the Argo CD extension with these defaults:

| Setting | Default | Description |
| --- | --- | --- |
| `name` | `"argocd-ext"` | Azure extension resource name. |
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
`node_count` must be at least four, or `min_count` must be at least four when
using autoscaling. The module cannot guarantee node placement, resource capacity,
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
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/aks?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  name                = "aks-example-dev-uksouth"
  resource_group_name = "rg-example-dev-uksouth"
  location            = "uksouth"
  dns_prefix          = "aks-example-dev"
  sku_tier            = "Free"

  auto_scaling_enabled        = true
  min_count                   = 3
  max_count                   = 5
  max_pods                    = 30
  vm_size                     = "Standard_D2s_v5"
  temporary_name_for_rotation = "rotatingpool"

  tenant_id              = "00000000-0000-0000-0000-000000000000"
  admin_group_object_ids = ["11111111-1111-1111-1111-111111111111"]
  local_account_disabled = true

  monitor_metrics = {
    annotations_allowed = "prometheus.io/scrape,prometheus.io/port,prometheus.io/path"
    labels_allowed      = "app,app.kubernetes.io/name,app.kubernetes.io/component,app.kubernetes.io/instance,k8s-app,env"
  }

  web_app_routing = {
    dns_zone_ids             = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/dnsZones/example.com"]
    default_nginx_controller = "External"
  }

  argocd = {
    high_availability = false
    namespace         = "argocd"
    namespace_install = false
  }
}
```

Replace the source revision with a published tag or commit. Replace example resource
names and object IDs with your own values. Pass outputs from other units through
Terragrunt `dependency` blocks when composing these modules.

## Behavior and upgrade considerations

The API server is private by default; clients need network connectivity and DNS
resolution. Supply administrator group object IDs or a tenant ID to enable Entra
integration. Local accounts are then disabled unless explicitly overridden.
Set `local_account_disabled = false` only when local administrator credentials
are needed, for example when consuming `kube_admin_config_raw`. Both kubeconfig
outputs are sensitive, but Terraform still stores credentials in state. Protect
state and prefer Entra authentication for routine access.

Autoscaling omits `node_count` and uses `min_count` and `max_count`. Without
autoscaling, only `node_count` controls capacity. Minimum and maximum counts must
be positive integers with the minimum no greater than the maximum. The rotation
name must differ from any existing node pool name. Node pool changes, including
zones and networking, may require rotation or replacement; review the plan.

Networking uses Azure CNI overlay with AKS default pod and service ranges. Ensure
those ranges do not overlap connected networks. For a custom subnet, attach a
user-assigned identity with the necessary Network Contributor permissions before
creating the cluster. Node public IPs remain disabled by default; enable them
with `node_public_ip_enabled = true` when required.

The module does not create role assignments, private DNS zones, Azure Monitor
workspaces, federated identity credentials, or Argo CD applications. Extension
installation uses AzureRM and does not require a Kubernetes provider or an admin
kubeconfig. Optional addons remain disabled until configured. Extension release
trains and settings depend on the selected Microsoft extension version.

## Tests

With Terraform >= 1.7.0, run `terraform init -backend=false`, `terraform validate`,
and `terraform test` in this directory. The tests cover addon defaults, configured
routing and metrics, Entra access, autoscaling limits, Argo CD namespaces, and HA
capacity checks. All tests use mocked providers and create no Azure resources.
