<!-- Frontmatter
name: Azure resource group
description: Create an Azure resource group with optional tags.
tags: [azure, module]
-->

# Azure resource group

Creates one Azure resource group. Requires Terraform >= 1.3.0 and the
`hashicorp/azurerm` provider >= 4.0.0 and < 5.0.0.

The caller must configure the AzureRM provider, including its `features` block,
subscription, and authentication. This module declares provider requirements
only; it does not configure a provider or backend.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | `string` | Yes | — | Resource group name. |
| `location` | `string` | Yes | — | Azure region, such as `uksouth`. |
| `tags` | `map(string)` | No | `{}` | Resource group tags. |

## Outputs

| Name | Description |
| --- | --- |
| `id` | Azure resource group ID. |
| `name` | Resource group name. |
| `location` | Resource group region. |
| `tags` | Resource group tags. |

## Terragrunt usage

Browse the catalog from an empty unit directory and select **Azure resource
group**, or create a `terragrunt.hcl` containing:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/azure/resource_group?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  name     = "rg-example-dev-uksouth"
  location = "uksouth"
  tags = {
    environment = "dev"
  }
}
```

Replace the source revision with a published Git tag or commit containing this
module. The consuming repository's Azure `root.hcl` should generate the provider
configuration and configure remote state. Supply credentials through the
caller's authentication mechanism, not module inputs.

Renaming or changing the location of the resource group requires replacement.
Review the plan before applying changes to a resource group containing resources.
