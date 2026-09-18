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

- [Terragrunt module unit](templates/module-unit/README.md): generate a unit for
  an existing Terraform module, with configurable root inclusion and inputs.

- [Azure resource group](azure/resource_group/README.md): create a resource group
  with optional tags and caller-managed provider configuration.

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

From an empty destination directory, browse a local checkout:

```sh
terragrunt catalog /absolute/path/to/platform-blueprints/terraform --root-file-name root.hcl
```

See [Terragrunt Catalog TUI](https://docs.terragrunt.com/features/catalog/tui/)
and [scaffolding](https://docs.terragrunt.com/features/catalog/scaffold/) for
discovery and template behavior.
