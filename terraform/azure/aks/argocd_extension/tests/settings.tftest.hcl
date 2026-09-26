mock_provider "azurerm" {}

variables {
  cluster_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-resource"
  minimum_node_count = 3
  settings           = { name_prefix = "paymentsuksdev" }
}

run "settings_default_name" {
  command = plan
  assert {
    condition     = azurerm_kubernetes_cluster_extension.argocd.name == "paymentsuksdevargocd"
    error_message = "The resource type must follow the shared name prefix."
  }
}

run "explicit_name_override" {
  command = plan
  variables { argocd = { name = "explicit-group" } }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.argocd.name == "explicit-group"
    error_message = "The explicit name must override the generated name."
  }
}

