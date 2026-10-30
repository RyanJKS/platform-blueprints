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

run "connection_outputs" {
  command = apply
  override_resource {
    target = azurerm_kubernetes_cluster.this
    values = {
      kube_config = [{
        host                   = "https://aks.example.com"
        client_certificate     = ""
        client_key             = ""
        cluster_ca_certificate = "dGVzdC1jYQ==" # pragma: allowlist secret
        username               = ""
        password               = ""
      }]
      fqdn         = "aks.example.com"
      private_fqdn = "aks.private.example.com"
    }
  }
  assert {
    condition = (
      output.host == "https://aks.example.com" &&
      base64decode(output.cluster_ca_certificate) == "test-ca" &&
      output.fqdn == "aks.example.com" &&
      output.private_fqdn == "aks.private.example.com"
    )
    error_message = "Connection outputs must preserve the endpoint, CA certificate, and DNS names."
  }
}

