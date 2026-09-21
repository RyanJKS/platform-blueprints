<!-- Frontmatter
name: Azure Kubernetes Service
description: Create an AKS cluster with a managed identity, a configurable system node pool,
and optional managed Prometheus, and application routing addons.
tags: [azure, module]
-->

# Azure Kubernetes Service

Create an AKS cluster with a managed identity, a configurable system node pool,
and optional managed Prometheus, and application routing addons.

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
| `default_node_pool` | `object` | No | `{}` | Default node pool settings, described below. |
| `identity_ids` | `set(string)` | No | `[]` | User-assigned identity resource IDs. An empty set uses a system-assigned identity. |
| `admin_group_object_ids` | `set(string)` | No | `[]` | Microsoft Entra group object IDs for cluster administrators. |
| `private_cluster_enabled` | `bool` | No | `true` | Whether to create a private API server endpoint. |
| `oidc_issuer_enabled` | `bool` | No | `true` | Whether to enable the OIDC issuer. |
| `workload_identity_enabled` | `bool` | No | `true` | Whether to enable workload identity. Requires the OIDC issuer. |
| `sku_tier` | `string` | No | `"Free"` | The AKS pricing tier. |
| `local_account_disabled` | `bool` | No | `null` | Null disables local accounts when Entra integration is enabled. |
| `tenant_id` | `string` | No | `null` | Entra tenant ID; also enables integration without administrator groups. |
| `azure_rbac_enabled` | `bool` | No | `true` | Use Azure RBAC for Entra integration. |
| `monitor_metrics` | `object` | No | `null` | Managed Prometheus settings, described below. |
| `web_app_routing` | `object` | No | `null` | Application routing settings, described below. |

## Default node pool settings

Set `default_node_pool` to an object containing only the attributes you want to
override. Omit it or use `{}` to retain all defaults. Attributes with non-null
defaults also use those defaults when explicitly set to `null`.

| Attribute | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | `"system"` | The name of the default Linux node pool. |
| `node_count` | `number` | `2` | The number of nodes when autoscaling is disabled. |
| `auto_scaling_enabled` | `bool` | `false` | Enable the cluster autoscaler for the default pool. |
| `min_count` | `number` | `3` | Minimum nodes when autoscaling is enabled. |
| `max_count` | `number` | `5` | Maximum nodes when autoscaling is enabled. |
| `max_pods` | `number` | `null` | Pods per node; null uses the AKS default. |
| `node_public_ip_enabled` | `bool` | `false` | Assign public IP addresses to nodes. |
| `temporary_name_for_rotation` | `string` | `"rotatingpool"` | Temporary node pool name during rotation. |
| `zones` | `list(string)` | `[]` | Availability zones for the default pool. |
| `os_disk_size_gb` | `number` | `null` | Node OS disk size; null uses the AKS default. |
| `vm_size` | `string` | `"Standard_D2s_v5"` | The virtual machine size for system nodes. |
| `vnet_subnet_id` | `string` | `null` | An existing subnet ID for the nodes. Null lets AKS manage networking. |

This replaces the previous standalone node pool inputs. Move those inputs into
`default_node_pool`, renaming `node_pool_name` to `name`. All other attribute
names and defaults are unchanged.

## Outputs

- `minimum_node_count`: Configured node count or autoscaling minimum for addon capacity validation.

- `id`: Id.
- `name`: Name.
- `location`: Location.
- `tags`: Tags.
- `node_resource_group`: Node resource group.
- `oidc_issuer_url`: Oidc issuer url.
- `identity`: Identity.
- `kubelet_identity`: Kubelet identity.

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

Deploy Argo CD separately with the [Argo CD extension module](../argocd_extension/README.md).

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/aks/cluster?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  name                = "aks-example-dev-uksouth"
  resource_group_name = "rg-example-dev-uksouth"
  location            = "uksouth"
  dns_prefix          = "aks-example-dev"
  sku_tier            = "Free"

  default_node_pool = {
    auto_scaling_enabled = true
    min_count            = 3
    max_count            = 5
    max_pods             = 30
  }

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
with `default_node_pool.node_public_ip_enabled = true` when required.

The module does not create role assignments, private DNS zones, Azure Monitor
workspaces, federated identity credentials, or Argo CD applications. Optional cluster addons remain disabled until configured.

## Tests

With Terraform >= 1.7.0, run `terraform init -backend=false`, `terraform validate`,
and `terraform test` in this directory. The tests cover addon defaults, configured routing and metrics, Entra access, autoscaling limits, and capacity outputs. All tests use mocked providers and create no Azure resources.
