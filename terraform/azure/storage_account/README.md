<!-- Frontmatter
name: Azure storage account
description: Create an Azure storage account with configurable protocols, data protection, and access controls.
tags: [azure, storage, module]
-->

# Azure storage account

Create an Azure storage account in an existing resource group. Defaults to Standard
StorageV2 with LRS replication. Requires
Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.7.0 and < 6.0.0. The caller configures provider
authentication, the AzureRM `features` block, subscription ID, and remote state.
Pin the selected provider version in the consuming root module's lock file.

The account defaults to HTTPS-only traffic and requires TLS 1.2 for TLS connections. Anonymous access to nested items, public
network access, and Shared Key authorization are disabled by default. Microsoft
Entra authorization is the portal default. Configure data-plane role assignments,
private endpoints, and private DNS separately before accessing data. Enabling
public network access permits authenticated access from any network; set `network_rules` to restrict access to selected networks. Disabling Shared Key authorization affects
clients and services that rely on account keys or account/service SAS tokens.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `settings` | `object` | Yes | — | Shared `name_prefix` and `region_long` strings. |
| `resource_group_name` | `string` | Yes | — | An existing resource group. |
| `name` | `string` | No | `null` | Globally unique account name; defaults to `${settings.name_prefix}sa`. |
| `location` | `string` | No | `null` | Defaults to `settings.region_long`. |
| `account_replication_type` | `string` | No | `LRS` | `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, or `RAGZRS`. |
| `access_tier` | `string` | No | `Hot` | `Hot` or `Cool`. |
| `public_network_access_enabled` | `bool` | No | `false` | Enable the public network endpoint. |
| `shared_access_key_enabled` | `bool` | No | `false` | Enable Shared Key authorization. |
| `tags` | `map(string)` | No | `{}` | Resource tags. |

Pass `settings = module.solution_settings.settings` when composing Terraform
modules. The full settings output is accepted; only the declared fields are used.
Pass tags separately with `tags = module.solution_settings.tags`. A nonempty
`name` or `location` overrides the corresponding default. Account names must
contain 3–24 lowercase letters or digits. Generated names are not truncated or
made unique; Azure checks global availability when creating the account.

## Additional inputs

All object inputs default to `null`, which omits the block. Optional object
attributes use provider defaults. Nested singleton blocks are objects; repeated
blocks such as `cors_rule` and `private_link_access` are lists of objects.
See [variables.tf](variables.tf) for the complete typed attribute definitions.

| Name | Default | Description |
| --- | --- | --- |
| `account_kind` | `StorageV2` | `Storage`, `StorageV2`, `BlobStorage`, `BlockBlobStorage`, or `FileStorage`. |
| `account_tier` | `Standard` | `Standard` or `Premium`; BlockBlobStorage and FileStorage require Premium. |
| `is_hns_enabled` | `false` | Enable the hierarchical namespace for Data Lake Storage Gen2. |
| `sftp_enabled` | `false` | Enable SFTP; requires HNS and local users. |
| `local_user_enabled` | `true` | Allow local user authentication; does not create users. |
| `nfsv3_enabled` | `false` | Enable Blob NFS v3; requires HNS. |
| `large_file_share_enabled` | `false` | Enable large file shares where supported. |
| `https_traffic_only_enabled` | `true` | Require HTTPS; explicitly disable when required by NFS workloads. |
| `default_to_oauth_authentication` | `true` | Default to Microsoft Entra authorization in the portal. |
| `infrastructure_encryption_enabled` | `false` | Enable encryption at the infrastructure layer. |
| `cross_tenant_replication_enabled` | `false` | Allow object replication across tenants. |
| `allowed_copy_scope` | `null` | Restrict copies to `AAD` or `PrivateLink`. |
| `queue_encryption_key_type` | `Service` | `Service` or `Account`. |
| `table_encryption_key_type` | `Service` | `Service` or `Account`. |
| `identity` | `null` | Managed identity `type` and optional `identity_ids`. |
| `network_rules` | `null` | Required `default_action`, optional `bypass`, `ip_rules`, `virtual_network_subnet_ids`, and `private_link_access`. |
| `blob_properties` | `null` | Versioning, change feed, access tracking, service version, CORS, delete retention, container retention, and restore policy. |
| `share_properties` | `null` | File service CORS, retention policy, and SMB settings. |
| `azure_files_authentication` | `null` | Directory type, optional Active Directory settings, and default share permission. |
| `routing` | `null` | Routing choice and publication of Microsoft or Internet endpoints. |
| `custom_domain` | `null` | Domain name and optional `use_subdomain`; configure DNS ownership verification separately. |
| `customer_managed_key` | `null` | Key Vault key ID and user-assigned identity ID; attach the identity and grant key access separately. |

`access_tier` applies only to StorageV2 and BlobStorage. HNS requires StorageV2 or
BlockBlobStorage and cannot be combined with blob versioning, change feed, or
point-in-time restore. Restore requires versioning, change feed, and a blob delete
retention period longer than the restore window. The module checks these
combinations during planning; Azure still enforces regional and SKU availability.

For SFTP, create `azurerm_storage_account_local_user` resources separately with
SSH authentication and permissions. Enabling SFTP does not provision users,
containers, or reachable endpoints. SFTP can incur additional Azure charges.
NFS v3 uses network-based authorization; configure private connectivity or
restricted network rules. HTTPS-only settings do not govern SFTP traffic.

Service properties may require data-plane connectivity and authorization during
Terraform operations. Configure the caller's AzureRM provider with
`storage_use_azuread = true` for supported operations when Shared Key is disabled,
and grant the runner appropriate data-plane roles. Some Azure Files operations
still require Shared Key. A private account requires a runner with private access.

### SFTP and Data Lake settings

Add these inputs to the Terragrunt example below:

```hcl
is_hns_enabled     = true
sftp_enabled       = true
local_user_enabled = true
```

### Blob protection and network restrictions

Use these inputs for a non-HNS account:

```hcl
public_network_access_enabled = true
network_rules = {
  default_action = "Deny"
  bypass         = ["None"]
  ip_rules       = ["203.0.113.10"] # Replace with your runner/client public IPv4 address.
}
identity = { type = "SystemAssigned" }
blob_properties = {
  versioning_enabled                  = true
  change_feed_enabled                 = true
  change_feed_retention_in_days        = 30
  delete_retention_policy              = { days = 14 }
  container_delete_retention_policy    = { days = 14 }
  restore_policy                      = { days = 7 }
}
```

## Outputs

- `id`: The storage account resource ID for role assignments or private endpoints.
- `name`: The storage account name.
- `location`: The Azure region.
- `tags`: The assigned tags.
- `primary_blob_endpoint`: The primary Blob service URL.
- `primary_dfs_endpoint`, `primary_file_endpoint`, `primary_queue_endpoint`,
  `primary_table_endpoint`, `primary_web_endpoint`: Service URLs where available.
- `identity`: Managed identity details, including principal and tenant IDs where available.

Account keys and connection strings are not exposed as module outputs. The
provider can still store credentials in Terraform state; protect the state backend.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/storage_account?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
  name                     = "paymentsuksdev123st"
  resource_group_name      = "rg-payments-dev-uksouth"
  account_replication_type = "ZRS"
  tags                     = { environment = "dev" }
}
```

Replace the revision with a published tag or commit and choose an available account
name. The example keeps public access disabled. Configure network access and
data-plane roles before using the Blob endpoint.

## Behavior and upgrade considerations

SFTP local users, containers, file shares, queues, tables, lifecycle policies, and private endpoints
are caller-managed. Premium accounts and hierarchical namespaces are configurable. Replication availability depends on the region. Review plans for
replacement when changing the name, resource group, location, or replication type.
Changes to HNS, NFS, account tier, or infrastructure encryption may replace the
account; review the plan before applying. Account deletion removes its data; configure backup and retention to match your
workload before storing production data.

## Validation

Mocked tests require Terraform >= 1.7.0 and do not deploy Azure resources:

```sh
terraform -chdir=terraform/azure/storage_account init -backend=false
terraform -chdir=terraform/azure/storage_account validate
terraform -chdir=terraform/azure/storage_account test
```
