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
      kube_config       = []
      kube_admin_config = []
    }
  }
  assert {
    condition = (
      output.kube_config_credentials == null &&
      output.kube_admin_config_credentials == null &&
      output.host == null &&
      output.client_certificate == null &&
      output.client_key == null &&
      output.cluster_ca_certificate == null &&
      output.username == null &&
      output.password == null
    )
    error_message = "Missing credential blocks must return null without an invalid index error."
  }
}
