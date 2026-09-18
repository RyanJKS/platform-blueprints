<!-- Frontmatter
name: Azure DNS zone
description: Create a public Azure DNS zone and expose its authoritative nameservers.
tags: [azure, dns, module]
-->

# Azure DNS zone

Creates one public Azure DNS zone in an existing resource group.

Requires Terraform >= 1.3.0 and `hashicorp/azurerm` >= 5.0.0. The caller configures
the AzureRM `features` block, subscription ID, authentication, and remote state.
This module declares provider requirements only and does not configure a provider
or backend. Pin the provider version in the consuming root module lock file.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | `string` | Yes | — | DNS zone name, such as `example.com`. |
| `resource_group_name` | `string` | Yes | — | Existing resource group name. |
| `tags` | `map(string)` | No | `{}` | DNS zone tags. |

DNS zones are global resources and do not require a location input.

## Outputs

| Name | Description |
| --- | --- |
| `id` | Azure DNS zone resource ID. |
| `name` | DNS zone name. |
| `name_servers` | Set of authoritative nameservers assigned by Azure. |
| `tags` | Tags assigned to the zone. |

## Terragrunt usage

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/dns?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  name                = "example.com"
  resource_group_name = "rg-dns-prod"
  tags = {
    environment = "prod"
  }
}
```

Replace the source revision with a published tag or commit and the example domain
with your own domain. Pass the resource group name through a Terragrunt
`dependency` block when composing modules.

## Behavior and upgrade considerations

Creating a zone does not register a domain or change its delegation. Configure
the returned `name_servers` at the domain registrar, or add an NS delegation in
the parent zone for a subdomain. Manage DNS records separately; Azure creates the
default NS and SOA records. This module does not create private DNS zones or VNet
links.

Renaming or replacing the zone can change its nameservers. Review the plan and
coordinate delegation changes to avoid disrupting DNS resolution.

## Tests

With Terraform >= 1.7.0, run `terraform init -backend=false`, `terraform validate`,
and `terraform test` from this directory. Tests use a mocked AzureRM provider;
the test's apply command creates no Azure resources and needs no Azure credentials.
The repository's PR workflow discovers and tests this module automatically.
