<!-- Frontmatter
name: Azure network security group
description: Create a network security group with configurable standalone security rules.
tags: [azure, network, module]
-->

# Azure network security group

Creates one NSG and its custom rules. Keep these resources together when they
share ownership and lifecycle. Rules use separate `azurerm_network_security_rule`
resources within the module so each rule has a stable identity keyed by name.

Requires Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.0.0. Configure AzureRM
authentication, the subscription ID, `features`, and remote state in the caller.
The module declares provider requirements only. Pin the provider version in the
consuming root module lock file.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `settings` | `object` | Yes | — | Shared naming and region defaults; see below. |
| `name` | `string` | No | `null` | NSG name. |
| `resource_group_name` | `string` | Yes | — | Existing resource group name. |
| `location` | `string` | No | `null` | Azure region. |
| `tags` | `map(string)` | No | `{}` | NSG tags. |
| `rules` | `map(object)` | No | `{}` | Custom rules keyed by Azure rule name. |

Each rule supports:

| Setting | Required | Default | Description |
| --- | --- | --- | --- |
| `priority` | Yes | — | Integer from 100 to 4096, unique within its direction. Lower numbers take precedence. |
| `direction` | Yes | — | `Inbound` or `Outbound`. |
| `access` | Yes | — | `Allow` or `Deny`. |
| `protocol` | Yes | — | `Tcp`, `Udp`, `Icmp`, `Esp`, `Ah`, or `*`. |
| `description` | No | `null` | Rule description. |
| `source_port_range` | No | `*` when neither source port selector is set | Single source port, range, or wildcard. |
| `source_port_ranges` | No | `null` | Set of source ports or ranges. |
| `destination_port_range` | One destination port selector | `null` | Single destination port, range, or wildcard. |
| `destination_port_ranges` | One destination port selector | `null` | Set of destination ports or ranges. |
| `source_address_prefix` | One source address selector | `null` | Source CIDR, IP address, service tag, or wildcard. |
| `source_address_prefixes` | One source address selector | `null` | Set of source CIDRs or IP addresses. |
| `source_application_security_group_ids` | One source address selector | `null` | Set of source application security group resource IDs. |
| `destination_address_prefix` | No | `*` when no destination address selector is set | Destination CIDR, IP address, service tag, or wildcard. |
| `destination_address_prefixes` | No | `null` | Set of destination CIDRs or IP addresses. |
| `destination_application_security_group_ids` | No | `null` | Set of destination application security group resource IDs. |

Address selectors are mutually exclusive for each side of a rule. Port selectors
are also mutually exclusive for each side. Supplied sets must not be empty. Use
singular address selectors for Azure service tags. Azure validates service-specific
port, address, and application security group restrictions.

## Outputs

- `id`: NSG resource ID for subnet or NIC association.
- `name`: NSG name.
- `location`: Azure region.
- `tags`: NSG tags.
- `rule_ids`: Custom rule resource IDs keyed by rule name.

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/networking/nsg?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

dependency "networking" {
  config_path = "../resource-group"
}

inputs = {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111" # Replace with your tenant ID.
  }
  name                = "aks-nsg"
  location            = dependency.networking.outputs.location
  resource_group_name = dependency.networking.outputs.name

  rules = {
    kube_apiserver_rule = {
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "203.0.113.10/32"
      destination_port_range     = "443"
    }

    # Optional: omit this entry when SSH access is not required.
    ssh_rule = {
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "203.0.113.10/32"
      destination_port_range     = "22"
    }
  }
}
```

Replace the source revision, dependency path, and documentation IP address with
your own values. Use a `/32` CIDR for a single IPv4 source address. The example
explicitly enables SSH; the module itself creates no custom rules unless supplied.

## Association and AKS behavior

The caller must associate the returned NSG ID with a subnet or network interface;
creating an NSG does not attach it to anything. Manage that association alongside
the subnet or NIC to keep network ownership clear. The existing VNet module does
not currently accept NSG IDs for its subnets.

An NSG on AKS nodes does not control the managed AKS API server endpoint. Configure
AKS API server authorized IP ranges for a public endpoint, or private connectivity
and DNS for a private endpoint. The port 443 example only permits matching traffic
to resources protected by this NSG. A port 22 rule also does not configure SSH
credentials, routing, or node public IP addresses.

Azure creates its built-in default rules even when `rules = {}`. No custom rules
does not mean all traffic is denied. Review effective rules and associations.

## Ownership and changes

Do not mix these standalone rule resources with inline `security_rule` blocks for
the same NSG. Avoid managing the same rule from multiple Terraform states. If
separate teams own rules independently, separate rule modules or states can be
appropriate, with a shared priority allocation policy.

Renaming a rule map key replaces that rule. Removing an entry deletes its rule.
Changing an associated NSG can affect connectivity; review the plan before apply.

## Tests

With Terraform >= 1.7.0, run `terraform init -backend=false`, `terraform validate`,
and `terraform test` from this directory. Mocked tests cover HTTPS and optional
SSH, plural selectors, application security groups, and invalid rules. They deploy
no Azure resources. The existing PR workflow discovers this module automatically.

## Shared solution settings

Pass the required `settings = module.solution_settings.settings` input. The module
accepts the full settings output and reads only the fields declared in its input
type. Pass tags separately with `tags = module.solution_settings.tags` where supported.

The default name is `${settings.name_prefix}nsg`, with no separator added.
A nonempty `name` overrides the generated name. Name resolution lives in
the top-level `locals` block, and the resource uses `local.name`.
`location` defaults to `settings.region_long`; an explicit nonempty location wins.

Generated names are not truncated or guaranteed unique. Review name changes in
the plan because they can replace existing resources.
