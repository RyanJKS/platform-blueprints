<!-- Frontmatter
name: Kubernetes manifest
description: Apply a Kubernetes manifest, including custom resources such as Argo CD Applications.
tags: [shared, kubernetes, manifest, module]
-->

# Kubernetes manifest

Manage one Kubernetes resource using `kubernetes_manifest`. Accepts built-in resources and custom resources such as an Argo CD `Application`. Use multiple module instances or `for_each` for multiple resources.

Requires Terraform >= 1.3.0 and HashiCorp Kubernetes provider >= 2.30.0, < 3.0.0. The caller configures the Kubernetes provider, credentials, and state backend. The cluster must be reachable during planning. Install any required CRD before planning a custom resource; `depends_on` alone does not solve schema discovery in a single initial apply. Deploy the cluster and Argo CD in earlier applies or separate Terragrunt units.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `manifest` | Required | One HCL object or `yamldecode()` result with `apiVersion`, `kind`, and `metadata.name`. Include `metadata.namespace` for namespaced resources. |
| `computed_fields` | `["metadata.annotations", "metadata.labels"]` | Field paths that the API server or controllers may modify. An override replaces this entire list. |
| `field_manager` | `{}` | Optional `name` (default `"Terraform"`) and `force_conflicts` (default `false`) for server-side apply. |
| `wait_fields` | `null` | Map of field paths to regular expressions. When configured, wait for all fields to match. |
| `timeouts` | `{}` | Optional `create`, `update`, and `delete` duration strings, each defaulting to `"10m"`. |

Only enable `force_conflicts` when intentionally taking ownership of fields from another manager. Keep field ownership separate from Argo CD or other controllers to avoid repeated overwrites. Computed fields allow API mutations; they are not equivalent to Terraform `ignore_changes`.

## Outputs

- `manifest`: Desired manifest, marked sensitive.
- `object`: Resulting Kubernetes object, including server-populated fields, marked sensitive.
- `name`, `namespace`, `kind`, `api_version`: Requested resource identity. `namespace` is `null` when omitted.

Manifests and resulting objects may contain secrets and remain in Terraform state. Protect the backend and use sensitive caller variables for secret inputs.

## Argo CD Application example

Configure provider access in the consuming root, then create the Application after Argo CD and its CRDs exist:

```hcl
provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

module "application" {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/shared/kubernetes_manifest?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "example"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/example/gitops.git"
        targetRevision = "main"
        path           = "apps/example"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "example"
      }
      syncPolicy = {
        automated   = { prune = false, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  wait_fields = {
    "status.health.status" = "^Healthy$"
    "status.sync.status"   = "^Synced$"
  }
}
```

Replace the source revision, repository URL, and application path before deploying. The Argo CD namespace must already exist. Omit `wait_fields` if Terraform should finish once the Application is applied instead of waiting for Argo CD reconciliation. Application deletion and child-resource cleanup follow Argo CD finalizer behavior; this module adds no finalizers automatically.

## Terragrunt usage

The root configuration must supply the Kubernetes provider and backend. Keep a single YAML document in `application.yaml` beside the unit:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/shared/kubernetes_manifest?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

dependencies {
  paths = ["../cluster", "../argocd"]
}

inputs = {
  manifest = yamldecode(file("${get_terragrunt_dir()}/application.yaml"))
}
```

Dependency ordering applies when running units together. The cluster and CRDs must still exist before planning this unit, including during an initial multi-unit plan.

## Validation and upgrades

Review CRD schema changes before upgrading custom resources. Changing resource identity may replace the object. Tests require Terraform >= 1.7.0 and use a mocked provider; they verify module wiring without contacting Kubernetes and cannot validate API schemas or controller behavior.

```sh
terraform init -backend=false
terraform validate
terraform test
```
