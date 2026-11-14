mock_provider "azurerm" {}

variables {
  name     = "test-resource"
  location = "uksouth"
}

run "unavailable_connection_outputs" {
  command = apply
  variables {
    name = "cluster-without-credentials"
  }
  override_resource {
    target = azurerm_kubernetes_cluster.this
    values = {
      kube_config = []
    }
  }
  assert {
    condition = (
      output.host == null &&
      output.cluster_ca_certificate == null
    )
    error_message = "Missing connection settings must return null without an invalid index error."
  }
}
