mock_provider "azurerm" {}

variables {
  cluster_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-resource"
  settings   = { name_prefix = "paymentsuksdev" }
  extension  = { extension_type = "microsoft.flux" }
}

run "generated_name" {
  command = plan
  assert {
    condition     = azurerm_kubernetes_cluster_extension.extension.name == "paymentsuksdevextension"
    error_message = "The extension must use the shared name prefix."
  }
}

run "explicit_name" {
  command = plan
  variables {
    extension = { extension_type = "microsoft.flux", name = "explicit-extension" }
  }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.extension.name == "explicit-extension"
    error_message = "An explicit name must override the generated name."
  }
}
