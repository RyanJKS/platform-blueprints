<!-- Frontmatter
name: Helm release
description: Install a Helm chart on an existing Kubernetes cluster, independent of cloud provider.
tags: [shared, kubernetes, helm, module]
-->

# Helm release

Manage one Helm release on an existing Kubernetes cluster. Supports repository charts, OCI chart references, and local chart paths. Use multiple module instances or `for_each` for multiple releases.

Requires Terraform >= 1.3.0 and the HashiCorp Helm provider >= 3.0.0, < 4.0.0. Configure the Helm provider, Kubernetes credentials, registry authentication, and Terraform backend in the caller. The module does not create a cluster or configure a provider.

## Inputs

`release` is required and accepts:

| Setting | Default | Description |
| --- | --- | --- |
| `name` | Required | Helm release name, a lowercase DNS label of at most 53 characters. |
| `chart` | Required | Chart name, local path, or chart URL including an OCI reference. |
| `repository` | `null` | Chart repository URL; omit for a full OCI reference or local path. |
| `version` | `null` | Chart version; pin this for reproducible deployments. When omitted, Helm selects the latest available version. |
| `namespace` | `"default"` | Kubernetes namespace for the release. |
| `create_namespace` | `false` | Create the release namespace when missing. |
| `description` | `null` | Release description. |
| `atomic` | `false` | Roll back a failed upgrade or remove a failed installation. Helm enables waiting when this is true. |
| `cleanup_on_fail` | `false` | Delete new resources created during a failed upgrade. |
| `dependency_update` | `false` | Update chart dependencies before installation. |
| `wait` | `true` | Wait for resources to become ready. |
| `wait_for_jobs` | `false` | Also wait for jobs when waiting is enabled. |
| `timeout` | `300` | Positive integer timeout in seconds. |
| `max_history` | `0` | Number of release revisions retained; zero means unlimited. |
| `skip_crds` | `false` | Skip installation of chart CRDs. |

Additional inputs:

- `values`: A list of YAML strings, default `[]`. Use `file()` or `yamlencode()` in the caller. Later documents override earlier documents. This input is marked sensitive.
- `set`: A list of `{ name, value, type }` objects, default `[]`. These override YAML values. `type` defaults to `"auto"`; use `"string"` to preserve string values such as numeric identifiers. Names follow Helm's value path and escaping rules.
- `set_sensitive`: The same structure as `set`, marked sensitive. Default `[]`. Avoid defining the same key in both lists.

Terraform stores sensitive values in state. Protect the state backend. Relative local chart paths resolve from the module execution directory; pass an absolute path when using a local chart.

## Outputs

- `id`: Helm release resource ID.
- `name`: Helm release name.
- `namespace`: Release namespace.
- `status`: Deployed release status.

## Terraform usage

Configure cluster access in the caller, then install any chart:

```hcl
provider "helm" {
  kubernetes = {
    config_path = pathexpand("~/.kube/config")
  }
}

module "argocd" {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/shared/helm_release?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"

  release = {
    name             = "argocd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "REPLACE_WITH_CHART_VERSION"
    namespace        = "argocd"
    create_namespace = true
    atomic           = true
    timeout          = 600
  }

  values = [yamlencode({
    server = {
      service = { type = "ClusterIP" }
    }
  })]
}
```

Replace both version placeholders before deploying. This is a Helm installation of Argo CD, independent of the Azure-managed extension module. Do not use both modules to manage the same installation.

## Terragrunt usage

The included root configuration must supply the Helm provider and backend:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/RyanJKS/platform-blueprints.git//terraform/shared/helm_release?ref=REPLACE_WITH_PUBLISHED_TAG_OR_COMMIT"
}

inputs = {
  release = {
    name       = "example"
    chart      = "oci://registry.example.com/charts/example"
    version    = "1.2.3"
    namespace  = "default"
  }
  values = [file("${get_terragrunt_dir()}/values.yaml")]
}
```

Replace the example chart reference and version with your chart. Deploy the cluster before the release and ensure the runner can reach its Kubernetes API.

## Upgrades and validation

Review chart upgrade notes and CRD migration requirements before changing `release.version`. Changing a release name or namespace can replace the release. Provider v3 uses lists of objects for `set` and `set_sensitive`; this module does not support provider v2.

Tests use a mocked Helm provider and require Terraform >= 1.7.0. They check module wiring and validation without downloading charts or contacting Kubernetes; they do not validate chart contents or deployment readiness.

```sh
terraform init -backend=false
terraform validate
terraform test
```
