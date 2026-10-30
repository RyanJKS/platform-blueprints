mock_provider "azurerm" {}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
  name                = "test-resource"
  resource_group_name = "rg-test"
  location            = "uksouth"
  dns_prefix          = "test-aks"
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
