mock_provider "azurerm" {}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
  cluster_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-resource"
  minimum_node_count = 3
}

run "configured_extension" {
  command = plan
  variables {
    argocd = {
      namespace              = "gitops"
      namespace_install      = true
      configuration_settings = { "configs.cm.url" = "https://argocd.example.com" }
    }
  }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.argocd.release_namespace == "gitops" && azurerm_kubernetes_cluster_extension.argocd.configuration_settings["namespaceInstall"] == "true" && azurerm_kubernetes_cluster_extension.argocd.configuration_settings["deployWithHighAvailability"] == "false" && azurerm_kubernetes_cluster_extension.argocd.configuration_settings["redis-ha.enabled"] == "false"
    error_message = "Argo CD must use the requested namespace and explicitly disable HA."
  }
}

run "argocd_ha_with_four_nodes" {
  command = plan
  variables {
    minimum_node_count = 4
    argocd             = { high_availability = true }
  }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.argocd.configuration_settings["deployWithHighAvailability"] == "true"
    error_message = "Argo CD HA must be enabled when four nodes are guaranteed."
  }
}

run "reject_argocd_ha_with_three_nodes" {
  command = plan
  variables {
    minimum_node_count = 3
    argocd             = { high_availability = true }
  }
  expect_failures = [azurerm_kubernetes_cluster_extension.argocd]
}

run "reject_invalid_namespace" {
  command = plan
  variables {
    argocd = { namespace = "Invalid_Namespace" }
  }
  expect_failures = [var.argocd]
}


run "reject_fractional_capacity" {
  command = plan
  variables { minimum_node_count = 3.5 }
  expect_failures = [var.minimum_node_count]
}
run "reserved_settings_cannot_bypass_ha" {
  command = plan
  variables {
    argocd = {
      configuration_settings = {
        deployWithHighAvailability = "true"
        "redis-ha.enabled"         = "true"
      }
    }
  }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.argocd.configuration_settings["deployWithHighAvailability"] == "false" && azurerm_kubernetes_cluster_extension.argocd.configuration_settings["redis-ha.enabled"] == "false"
    error_message = "Typed HA settings must override configuration_settings."
  }
}
