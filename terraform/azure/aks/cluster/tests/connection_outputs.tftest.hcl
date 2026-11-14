mock_provider "azurerm" {}

variables {
  name     = "test-resource"
  location = "uksouth"
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

