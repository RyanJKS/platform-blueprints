# Terraform catalog

This directory is a Terragrunt catalog for reusable Terraform modules and
scaffolding templates. Use a current Terragrunt release with **Template** discovery
in the Catalog TUI. Terragrunt v0.71.1 does not discover standalone templates.

## Use from a Terragrunt repository

Add this block to your repository's `root.hcl`:

```hcl
catalog {
  urls = [
    "github.com/RyanJKS/platform-blueprints//terraform",
  ]
}
```

Create an empty directory for the new unit, then launch the catalog there:

```sh
mkdir -p dev/my-unit
cd dev/my-unit
terragrunt catalog --root-file-name root.hcl
```

Select **Terragrunt module unit**, press `s`, and enter the module source and
inputs. The generated `terragrunt.hcl` includes your existing `root.hcl` by
default. Configure providers, credentials, and remote state in the consuming
repository as required by your module. Scaffolding does not deploy resources.

You can also browse without configuring a catalog block:

```sh
terragrunt catalog github.com/RyanJKS/platform-blueprints//terraform --root-file-name root.hcl
```

After these changes are pushed, the remote catalog can discover them. For
reproducible reuse, append `?ref=<tag-or-commit>` to the catalog URL, replacing the
placeholder with a published Git tag or commit. Pin the generated module source
separately; a catalog revision does not pin an arbitrary module source.

## Available entries

Azure modules are grouped under `networking/` and `aks/` where related modules exist. `database/` reserves space for future service-specific modules. Grouping directories contain no `.tf` files.

- [AKS Argo CD extension](azure/aks/argocd_extension/README.md): install Argo CD on an existing AKS cluster.
- [AKS migration guidance](azure/aks/README.md#migration): update existing cluster, extension, and networking consumers.

- [Azure network security group](azure/networking/nsg/README.md): create an NSG with configurable custom rules.
- [Azure RBAC assignment](azure/rbac/README.md): assign roles to users, groups, service principals, and managed identities.
- [Azure DNS zone](azure/networking/dns/README.md): create a public DNS zone and expose its authoritative nameservers.
- [Terragrunt module unit](templates/module-unit/README.md): generate a unit for
  an existing Terraform module, with configurable root inclusion and inputs.

- [Azure resource group](azure/resource_group/README.md): create a resource group
  with optional tags and caller-managed provider configuration.
- [Azure virtual network](azure/networking/vnet/README.md): Create an Azure virtual network with optional subnets.
- [Azure managed identity](azure/managed_identity/README.md): Create a user-assigned Azure managed identity.
- [Azure Key Vault](azure/keyvault/README.md): Create an Azure Key Vault with RBAC authorization and purge protection.
- [Azure storage account](azure/storage_account/README.md): Create a storage account with HNS, SFTP, NFS, data protection, and access controls.
- [Microsoft Entra security group](azure/ad_group/README.md): Create a Microsoft Entra ID security group with optional owners and members.
- [Azure Kubernetes Service](azure/aks/cluster/README.md): Create an AKS cluster with a managed identity and a system node pool.

Azure resource modules require AzureRM >= 5.0.0. Microsoft Entra groups require
AzureAD >= 3.0.0 < 4.0.0 because groups are managed through Microsoft Graph.
Provider configuration, credentials, and state remain caller-managed.

The `aws/` directory is reserved for future modules.

## Add a module

Create a directory such as `aws/s3-bucket/` or `azure/resource-group/` with real
Terraform configuration:

```text
aws/s3-bucket/
  README.md
  main.tf
  variables.tf
  outputs.tf
  versions.tf
```

Each module should declare its Terraform and provider requirements, describe
every input and output, and leave provider configuration and backend selection
to the caller. Do not add placeholder `.tf` files to grouping directories.

Terragrunt discovers modules from their `.tf` files and uses its built-in
scaffolding template to generate a unit from their variable declarations. No
central module registry file is required. Add an optional `.boilerplate/`
directory only when the module needs custom scaffolding.

Give each module a README with catalog metadata:

```markdown
<!-- Frontmatter
name: AWS S3 bucket
description: A reusable S3 bucket module.
tags: [aws, storage, module]
-->

# AWS S3 bucket
```

Document requirements, inputs, outputs, examples, and upgrade considerations.
Keep runnable examples outside this catalog directory so they do not appear as
separate entries.

## Local development

The `Terraform tests` GitHub Actions workflow runs on every pull request. It checks
formatting, then initializes, validates, and tests each module under
all directories containing Terraform files beneath `terraform/` sequentially in one job. It uses mocked tests without
Azure credentials. There is no matrix or workflow concurrency configuration.

The Azure modules include mocked plan tests for networking, AKS, Key Vault, and
Entra groups. Tests require Terraform >= 1.7.0 and do not deploy Azure resources.
For example:

```sh
terraform -chdir=terraform/azure/aks/cluster init -backend=false
terraform -chdir=terraform/azure/aks/cluster validate
terraform -chdir=terraform/azure/aks/cluster test
terraform fmt -check -recursive terraform
```

From an empty destination directory, browse a local checkout:

```sh
terragrunt catalog /absolute/path/to/platform-blueprints/terraform --root-file-name root.hcl
```

See [Terragrunt Catalog TUI](https://docs.terragrunt.com/features/catalog/tui/)
and [scaffolding](https://docs.terragrunt.com/features/catalog/scaffold/) for
discovery and template behavior.
