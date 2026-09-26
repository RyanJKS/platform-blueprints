mock_provider "azurerm" {}

variables {
  cluster_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-resource"
  settings   = { name_prefix = "test" }
  extension  = { extension_type = "microsoft.flux" }
}

run "non_argocd_extension" {
  command = plan
  assert {
    condition = (
      azurerm_kubernetes_cluster_extension.extension.extension_type == "microsoft.flux" &&
      azurerm_kubernetes_cluster_extension.extension.release_train == "Stable" &&
      length(azurerm_kubernetes_cluster_extension.extension.configuration_settings) == 0
    )
    error_message = "The module must support other extension types without injecting Argo CD settings."
  }
}

run "custom_settings" {
  command = plan
  variables {
    extension = {
      extension_type    = "microsoft.argocd"
      release_train     = "preview"
      release_namespace = "gitops"
      version           = "1.0.0"
      configuration_settings = {
        deployWithHighAvailability = "true"
        "redis-ha.enabled"         = "true"
        namespaceInstall           = "false"
      }
    }
    configuration_protected_settings = { token = "test-secret" }
  }
  assert {
    condition = (
      azurerm_kubernetes_cluster_extension.extension.release_namespace == "gitops" &&
      azurerm_kubernetes_cluster_extension.extension.version == "1.0.0" &&
      azurerm_kubernetes_cluster_extension.extension.configuration_settings == var.extension.configuration_settings &&
      azurerm_kubernetes_cluster_extension.extension.configuration_protected_settings["token"] == "test-secret"
    )
    error_message = "The module must pass through deployment settings without extension-specific overrides."
  }
}

run "reject_invalid_namespace" {
  command = plan
  variables {
    extension = { extension_type = "microsoft.flux", release_namespace = "Invalid_Namespace" }
  }
  expect_failures = [var.extension]
}

run "reject_empty_extension_type" {
  command = plan
  variables {
    extension = { extension_type = " " }
  }
  expect_failures = [var.extension]
}

run "preview_release_train" {
  command = plan
  variables {
    extension = { extension_type = "microsoft.argocd", release_train = "preview" }
  }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.extension.release_train == "preview"
    error_message = "Unpinned extensions must use the requested release train."
  }
}
