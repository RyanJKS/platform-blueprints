mock_provider "kubernetes" {}

variables {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata   = { name = "example", namespace = "default" }
    data       = { example = "value" }
  }
}

run "generic_manifest" {
  command = plan
  assert {
    condition = (
      kubernetes_manifest.this.manifest == var.manifest &&
      output.name == "example" &&
      output.namespace == "default" &&
      output.kind == "ConfigMap" &&
      output.api_version == "v1" &&
      !kubernetes_manifest.this.field_manager[0].force_conflicts &&
      length(kubernetes_manifest.this.wait) == 0
    )
    error_message = "The module must preserve arbitrary manifests without forcing field ownership or waiting by default."
  }
}

run "argocd_application" {
  command = plan
  variables {
    manifest = {
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "Application"
      metadata   = { name = "example", namespace = "argocd" }
      spec = {
        project = "default"
        source = {
          repoURL        = "https://github.com/example/gitops.git"
          targetRevision = "main"
          path           = "apps/example"
        }
        destination = { server = "https://kubernetes.default.svc", namespace = "example" }
      }
    }
    computed_fields = ["metadata.annotations", "metadata.labels", "spec.source.targetRevision"]
    field_manager   = { name = "platform", force_conflicts = true }
    wait_fields     = { "status.health.status" = "^Healthy$" }
    timeouts        = { create = "20m", update = "15m", delete = "5m" }
  }
  assert {
    condition = (
      kubernetes_manifest.this.manifest == var.manifest &&
      kubernetes_manifest.this.field_manager[0].name == "platform" &&
      kubernetes_manifest.this.field_manager[0].force_conflicts &&
      kubernetes_manifest.this.wait[0].fields["status.health.status"] == "^Healthy$" &&
      contains(kubernetes_manifest.this.computed_fields, "spec.source.targetRevision") &&
      kubernetes_manifest.this.timeouts[0].create == "20m" &&
      kubernetes_manifest.this.timeouts[0].update == "15m" &&
      kubernetes_manifest.this.timeouts[0].delete == "5m"
    )
    error_message = "Custom resources must retain their spec and configured apply controls."
  }
}

run "cluster_scoped_manifest" {
  command = plan
  variables {
    manifest = { apiVersion = "v1", kind = "Namespace", metadata = { name = "example" } }
  }
  assert {
    condition     = output.namespace == null && output.name == "example"
    error_message = "Cluster-scoped resources must not require a namespace."
  }
}

run "reject_missing_name" {
  command = plan
  variables {
    manifest = { apiVersion = "v1", kind = "ConfigMap", metadata = { name = "" } }
  }
  expect_failures = [var.manifest]
}
