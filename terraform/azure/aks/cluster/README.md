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
| `settings` | `object` | Yes | — | Shared naming and region defaults; see below. |
| `name` | `string` | No | `null` | The resource name. |
| `resource_group_name` | `string` | Yes | — | The name of the existing resource group. |
| `location` | `string` | No | `null` | The Azure region in which to create the resource. |
| `tags` | `map(string)` | No | `{}` | Tags to assign to the resource. |
| `dns_prefix` | `string` | No | `null` | Set exactly one of this or `dns_prefix_private_cluster`. |
| `kubernetes_version` | `string` | No | `"1.37"` | The Kubernetes version. Null uses the regional Azure default. |
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
| `monitor_metrics` | `object` | No | `{}` | Managed Prometheus settings, described below. |
| `web_app_routing` | `object` | No | `{}` | Application routing settings, described below. |

## Private networking and integrations

The following inputs extend the existing node pool, control-plane identity, Entra, and managed Prometheus settings:

| Input | Default | Settings |
| --- | --- | --- |
| `dns_prefix_private_cluster` | `null` | Alternative to `dns_prefix`; requires a private cluster and a custom private DNS zone. |
| `private_dns_zone_id` | `null` | Existing private DNS zone resource ID, `"System"`, or `"None"`. |
| `kubelet_identity` | `null` | Required `client_id`, `object_id`, and `user_assigned_identity_id` for an existing identity. Requires user-assigned control-plane identity via `identity_ids`. |
| `network_profile` | Azure CNI overlay | Required `network_plugin`; optional `network_plugin_mode`, `network_policy`, `network_data_plane`, `dns_service_ip`, `service_cidr`, `pod_cidr`, `outbound_type` (default `"loadBalancer"`), and `load_balancer_sku` (default `"standard"`). |
| `ingress_application_gateway` | `null` | Required `gateway_id` for an existing Application Gateway. |
| `key_management_service` | `null` | Required `key_vault_key_id`; optional `key_vault_network_access`, either `"Public"` (default) or `"Private"`. |
| `oms_agent` | `null` | Required `log_analytics_workspace_id`; optional `msi_auth_for_monitoring_enabled` (default `true`). |

Omitting `network_profile` preserves the existing Azure CNI overlay configuration. Supplying a profile replaces it; for subnet-based Azure CNI, set `network_plugin = "azure"` and omit `network_plugin_mode`, as below. Set service and pod ranges that do not overlap connected networks, and choose a DNS service IP within the service range. Review network changes carefully because Azure may require cluster replacement or node rotation.

The new addons are disabled unless configured. Existing `monitor_metrics` and `web_app_routing` defaults remain enabled with `{}`; use `null` to disable either. Application Gateway ingress and application routing are separate addons. Disable application routing when only Application Gateway is needed.

Additional outputs `ingress_application_gateway_identity` and `oms_agent_identity` expose addon identities for downstream role assignments. The existing `kubelet_identity` output exposes the configured or generated kubelet identity.

### Example with existing infrastructure

The following module call assumes the referenced resources and data sources exist in the caller:

```hcl
module "aks" {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/aks/cluster?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"

  settings                   = module.solution_settings.settings
  name                       = "aks-01"
  location                   = data.azurerm_resource_group.rg_01.location
  resource_group_name        = data.azurerm_resource_group.rg_01.name
  private_cluster_enabled    = true
  dns_prefix_private_cluster = "aks-01"
  private_dns_zone_id         = data.azurerm_private_dns_zone.aks.id
  kubernetes_version         = null # Use the regional default, or pin a supported version.
  local_account_disabled     = true
  sku_tier                   = "Standard"

  default_node_pool = {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = data.azurerm_subnet.aks_01.id
  }

  identity_ids = [azurerm_user_assigned_identity.controlplane.id]
  kubelet_identity = {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  network_profile = {
    network_plugin = "azure"
    dns_service_ip = "10.1.3.4"
    service_cidr   = "10.1.3.0/24"
  }

  ingress_application_gateway = {
    gateway_id = azurerm_application_gateway.agw_01.id
  }
  web_app_routing = null

  key_management_service = {
    key_vault_key_id         = azurerm_key_vault_key.kms.id
    key_vault_network_access = "Private"
  }

  admin_group_object_ids = var.cluster_admin_ids
  azure_rbac_enabled     = true

  oms_agent = {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.log.id
    msi_auth_for_monitoring_enabled = true
  }
  monitor_metrics = {}

  depends_on = [
    azurerm_role_assignment.controlplane_identity_contributor,
    azurerm_role_assignment.controlplane_keyvault_crypto_user,
    azurerm_role_assignment.controlplane_resourcegroup_contributor,
  ]
}
```

Keep role assignments in the caller and reference all required assignments in the module's `depends_on`, including any additional DNS, subnet, or kubelet identity assignments. `depends_on` is a Terraform module meta-argument, not an input variable. The module does not create the identities, gateway, private DNS zone, Key Vault key, workspace, or their permissions.

For custom private DNS, grant the control-plane identity the required Private DNS Zone Contributor and network permissions. An external kubelet identity requires Managed Identity Operator permissions for the control-plane identity. Configure the Key Vault cryptographic permissions and private connectivity required by AKS KMS; `key_vault_network_access = "Private"` does not create private endpoints or DNS. Grant the ingress addon identity the required Application Gateway permissions using the new identity output.

AzureRM 5 uses managed Entra integration without a `managed` argument. Continue using `admin_group_object_ids`, `tenant_id`, and `azure_rbac_enabled`. Set administrator groups or an explicit tenant ID when disabling local accounts. Choose an AKS version supported in your region; the example does not carry forward the old `1.28` version.

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

## Additional node pools

Use `additional_node_pools` for autoscaled Linux user pools. The map key is the
Azure pool name. Existing callers retain the same system pool and create no
additional pools unless configured. For example, add these inputs to your module
or Terragrunt configuration:

```hcl
default_node_pool = {
  name       = "system"
  vm_size    = "Standard_D4s_v5"
  node_count = 3
  zones      = ["1", "2", "3"]
  # vnet_subnet_id = dependency.network.outputs.aks_subnet_id
}

additional_node_pools = {
  general = {
    vm_size                     = "Standard_D8s_v5"
    min_count                   = 3
    max_count                   = 20
    temporary_name_for_rotation = "generaltemp"
  }
  memory = {
    vm_size                     = "Standard_E16s_v5"
    min_count                   = 1
    max_count                   = 10
    temporary_name_for_rotation = "memorytemp"
    node_labels                 = { workload = "memory" }
    node_taints                 = ["workload=memory:NoSchedule"]
  }
  gpu = {
    vm_size                     = "Standard_NC24ads_A100_v4"
    min_count                   = 0
    max_count                   = 5
    temporary_name_for_rotation = "gputemp"
    node_labels                 = { workload = "gpu" }
    node_taints                 = ["sku=gpu:NoSchedule"]
    # Override zones to match GPU availability in your region.
  }
  spot = {
    vm_size                     = "Standard_D8s_v5"
    min_count                   = 0
    max_count                   = 20
    priority                    = "Spot"
    eviction_policy             = "Delete"
    spot_max_price              = -1
    temporary_name_for_rotation = "spottemp"
  }
}
```

Every additional pool requires `vm_size`, `min_count`, and `max_count`. Minimums
may be zero; maximums must be positive. Pools inherit the default pool subnet
unless `vnet_subnet_id` is set. Zones default to `["1", "2", "3"]`; override them
for regional SKU availability. Validate VM quotas and capacity before deployment.

Optional settings include `max_pods`, `os_disk_size_gb`, `node_labels`,
`node_taints`, `fips_enabled`, and `host_encryption_enabled`. Both security flags
default to false. `os_disk_type` defaults to `Managed`; select `Ephemeral` only
with a compatible VM size and sufficient local disk capacity. Rotation names are
optional, must be unique, and must not match pool names or the default pool's
rotation name. Set one before changes that require node pool rotation.

Regular pools default to a 60-minute drain timeout, `max_surge = "10%"`, a
3-minute soak, and `undrainable_node_behavior = "Schedule"`. Override these with
`drain_timeout_in_minutes`, `max_surge`, `node_soak_duration_in_minutes`, and
`undrainable_node_behavior`. Set `max_unavailable` instead of `max_surge` to use
unavailable-node upgrades; explicitly setting both is rejected. Spot pools omit
upgrade settings because they do not support surge upgrades. Spot priority uses
`Delete` eviction and `spot_max_price = -1` by default.

The autoscaler owns additional pool capacity after creation. Terraform ignores
changes to `node_count`, `orchestrator_version`, and `workload_runtime` on these
pools. `kubernetes_version` supplies their initial version; configure AKS or Fleet
upgrade management separately. This module does not create an upgrade schedule.
The default system pool keeps its existing version and capacity behavior.

Use node selectors or affinity and matching tolerations for memory and GPU
workloads. GPU workloads also need the NVIDIA device plugin and GPU resource
requests. AKS adds its Spot priority label and `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`
taint; Spot workloads need the matching toleration. A zero-node pool scales up
only when pending workloads can be scheduled on it. GPU setup and workload
scheduling are outside this module.

`additional_node_pool_ids` returns resource IDs keyed by pool name.
`minimum_node_count` continues to describe only the default pool, so optional,
tainted, GPU, and Spot capacity is not counted toward addon capacity checks.

## Container Insights data collection

Set `container_insights = {}` alongside `oms_agent` to create a Container Insights
DCR and its cluster association using the same existing Log Analytics workspace:

```hcl
oms_agent = {
  log_analytics_workspace_id      = dependency.monitoring.outputs.workspace_id
  msi_auth_for_monitoring_enabled = true
}

container_insights = {
  streams                  = ["Microsoft-ContainerInsights-Group-Default"]
  data_collection_interval = "1m"
  namespace_filtering_mode = "Off"
  namespaces               = []
  enable_container_log_v2   = true
}
```

The example shows the defaults. `container_insights = null` creates no rule or
association and preserves existing `oms_agent` behavior. A managed rule requires
`oms_agent` with managed identity authentication enabled. Collection intervals
accept `1m`, `5m`, `10m`, `15m`, or `30m`. Namespace filtering accepts `Off`,
`Include`, or `Exclude`. Supply the namespace list for filtering and select
supported Container Insights streams for your collection requirements. Namespace
filtering applies only to tables that support it, not all cluster telemetry.

The rule name is `MSCI--<cluster-name>` and the association name is
`ContainerInsightsExtension`. Import existing rules and associations into these
resource addresses before enabling this option if Azure or another deployment
already manages them. Avoid overlapping rules that duplicate ingestion.
The module creates no workspace or role assignments. This DCR is separate from
managed Prometheus configuration. `container_insights_data_collection_rule_id`
returns the rule ID, or null when disabled.

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

- `kube_config`: Sensitive raw kubeconfig YAML, an alias of `kube_config_raw`.
- `kube_config_credentials`: Sensitive connection object, or `null` when unavailable.
- `host`: Sensitive Kubernetes API endpoint from the kubeconfig.
- `client_certificate`, `client_key`, `cluster_ca_certificate`: Sensitive base64-encoded certificate fields and private key.
- `username`, `password`: Sensitive authentication fields, which may be empty depending on authentication mode.
- `kube_admin_config_credentials`: Sensitive administrator connection object, or `null` when unavailable.
- `fqdn`, `private_fqdn`: API server DNS names, when configured.

### Connection dependencies

A downstream Terraform root can configure the Helm provider using these outputs:

```hcl
variable "aks_connection" {
  type = object({
    host                   = string
    client_certificate     = string
    client_key             = string
    cluster_ca_certificate = string
  })
  sensitive = true
}

provider "helm" {
  kubernetes = {
    host                   = var.aks_connection.host
    client_certificate     = base64decode(var.aks_connection.client_certificate)
    client_key             = base64decode(var.aks_connection.client_key)
    cluster_ca_certificate = base64decode(var.aks_connection.cluster_ca_certificate)
  }
}
```

Supply the object from the downstream unit's `terragrunt.hcl`:

```hcl
dependency "cluster" {
  config_path = "../cluster"
}

inputs = {
  aks_connection = dependency.cluster.outputs.kube_config_credentials
}
```

Individual fields are also available, for example `dependency.cluster.outputs.client_certificate`. In Terraform, use `module.aks.kube_config_credentials` with your actual module call name. Configure the provider in the consuming root; the shared Helm release module inherits it.

The certificate example requires usable client credentials. Entra-enabled clusters may return empty client certificate/key fields and require exec authentication, such as `kubelogin`, instead. Administrator credentials are unavailable when local accounts are disabled. These outputs do not change cluster authentication settings.

Missing connection blocks return `null`; Terraform omits null root outputs, so consumers must account for unavailable credentials. Individual provider fields may also be empty strings. `kube_config` is raw YAML, not the structured object. Decode certificate fields when configuring providers; do not base64-decode the raw YAML.

Deploy the cluster before downstream releases. The runner must reach the cluster API, including private networking when enabled. Sensitive outputs remain in Terraform state; protect the backend and mark downstream credential variables sensitive.

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

Deploy Argo CD separately with the [extension module](../extension/README.md).

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/aks/cluster?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111" # Replace with your tenant ID.
  }
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
and `terraform test` in this directory. The tests cover addon defaults, configured routing and metrics, Entra access, autoscaling limits, and capacity outputs. The tests also cover mixed user pools, zero-node GPU and Spot pools, invalid pool settings, and Container Insights configuration and prerequisites. All tests use mocked providers and create no Azure resources.

## Shared solution settings

Pass the required `settings = module.solution_settings.settings` input. The module
accepts the full settings output and reads only the fields declared in its input
type. Pass tags separately with `tags = module.solution_settings.tags` where supported.

The default name is `${settings.name_prefix}aks`, with no separator added.
A nonempty `name` overrides the generated name. Name resolution lives in
the top-level `locals` block, and the resource uses `local.name`.
`location` defaults to `settings.region_long`; an explicit nonempty location wins.
`tenant_id` defaults to `settings.tenant_id`; an explicit nonempty tenant ID wins.
Passing settings alone does not enable Entra integration. `dns_prefix` remains explicit.

Generated names are not truncated or guaranteed unique. Review name changes in
the plan because they can replace existing resources.
