mock_provider "azurerm" {}

variables {
  cluster_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-resource"
  settings   = { name_prefix = "test" }
  extension  = { extension_type = "microsoft.flux" }
}

run "extension_without_identity" {
  command = apply

  override_resource {
    target = azurerm_kubernetes_cluster_extension.extension
    values = {
      aks_assigned_identity = []
    }
  }

  assert {
    condition     = output.aks_assigned_identity == null
    error_message = "Extensions without an Azure-assigned identity must return null."
  }
}
