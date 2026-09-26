# Terraform catalog

The `terraform/` directory is a Terragrunt catalog for infrastructure modules
and scaffolding templates. Its first entry generates a Terragrunt unit for an
existing Terraform module. The catalog includes Azure modules for resource groups,
virtual networks, AKS, Key Vault, user-assigned managed identities, and Microsoft
Entra security groups.
Azure resource modules require AzureRM >= 5.0.0; Entra groups use AzureAD 3.x.
The catalog also includes public Azure DNS zones with nameserver outputs for
domain delegation, Azure RBAC assignments with explicit principal types, and
network security groups with configurable custom rules.
Provider configuration and state remain caller-managed.

Use a current Terragrunt release that supports standalone template discovery.
Add this block to an existing `root.hcl` in your Terragrunt repository:

```hcl
catalog {
  urls = ["github.com/RyanJKS/platform-blueprints//terraform"]
}
```

From an empty unit directory below that root, run:

```sh
terragrunt catalog --root-file-name root.hcl
```

Select **Terragrunt module unit**, press `s`, and supply the module source and
inputs. The generated unit includes your existing `root.hcl` by default.
Review it before planning or deploying.

The changes must be published to GitHub before remote discovery can find them.
Append `?ref=<tag-or-commit>` to the catalog URL to pin a published revision.

See the [catalog README](https://github.com/RyanJKS/platform-blueprints/blob/main/terraform/README.md)
for local browsing, module authoring, and compatibility details.
