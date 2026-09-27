mock_provider "helm" {}

variables {
  release = {
    name       = "example"
    chart      = "example-chart"
    repository = "https://charts.example.com"
  }
}

run "defaults" {
  command = plan

  assert {
    condition = (
      helm_release.this.name == "example" &&
      helm_release.this.namespace == "default" &&
      !helm_release.this.create_namespace &&
      helm_release.this.wait &&
      helm_release.this.timeout == 300
    )
    error_message = "The release must preserve the requested name and documented deployment defaults."
  }
}

run "configured_release" {
  command = plan

  variables {
    release = {
      name              = "gitops"
      chart             = "argo-cd"
      repository        = "https://argoproj.github.io/argo-helm"
      version           = "7.7.0"
      namespace         = "argocd"
      create_namespace  = true
      atomic            = true
      cleanup_on_fail   = true
      dependency_update = true
      wait_for_jobs     = true
      timeout           = 600
      max_history       = 10
      skip_crds         = true
    }
    values        = ["server:\n  replicas: 2\n", "server:\n  replicas: 3\n"]
    set           = [{ name = "server.service.type", value = "ClusterIP", type = "string" }]
    set_sensitive = [{ name = "example.token", value = "test-token" }]
  }

  assert {
    condition = (
      helm_release.this.chart == "argo-cd" &&
      helm_release.this.repository == "https://argoproj.github.io/argo-helm" &&
      helm_release.this.version == "7.7.0" &&
      helm_release.this.namespace == "argocd" &&
      helm_release.this.create_namespace &&
      helm_release.this.atomic &&
      helm_release.this.cleanup_on_fail &&
      helm_release.this.dependency_update &&
      helm_release.this.wait_for_jobs &&
      helm_release.this.timeout == 600 &&
      helm_release.this.max_history == 10 &&
      helm_release.this.skip_crds
    )
    error_message = "Chart selection and deployment controls must reach the Helm provider."
  }

  assert {
    condition = (
      helm_release.this.values == var.values &&
      one(helm_release.this.set).value == "ClusterIP" &&
      one(helm_release.this.set).type == "string" &&
      one(helm_release.this.set_sensitive).value == "test-token"
    )
    error_message = "Values order and individual overrides must be preserved."
  }
}

run "oci_chart" {
  command = plan
  variables {
    release = { name = "example", chart = "oci://registry.example.com/charts/example", version = "1.2.3" }
  }
  assert {
    condition     = helm_release.this.chart == "oci://registry.example.com/charts/example"
    error_message = "OCI chart references must work without an HTTP repository."
  }
}

run "invalid_name" {
  command = plan
  variables {
    release = { name = "Invalid_Name", chart = "example" }
  }
  expect_failures = [var.release]
}

run "invalid_timeout" {
  command = plan
  variables {
    release = { name = "example", chart = "example", timeout = 0 }
  }
  expect_failures = [var.release]
}

run "invalid_set_type" {
  command = plan
  variables {
    set = [{ name = "replicas", value = "2", type = "number" }]
  }
  expect_failures = [var.set]
}
