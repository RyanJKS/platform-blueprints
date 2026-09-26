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
      kube_config_raw = "test-kubeconfig-yaml"
      kube_config = [{
        host                   = "https://aks.example.com"
        client_certificate     = "dGVzdC1jZXJ0" # pragma: allowlist secret
        client_key             = "dGVzdC1rZXk=" # pragma: allowlist secret
        cluster_ca_certificate = "dGVzdC1jYQ==" # pragma: allowlist secret
        username               = "test-user"
        password               = "test-password" # pragma: allowlist secret
      }]
      kube_admin_config_raw = "test-admin-yaml"
      kube_admin_config = [{
        host                   = "https://aks.example.com"
        client_certificate     = "YWRtaW4tY2VydA==" # pragma: allowlist secret
        client_key             = "YWRtaW4ta2V5"     # pragma: allowlist secret
        cluster_ca_certificate = "dGVzdC1jYQ=="     # pragma: allowlist secret
        username               = "admin-user"
        password               = "admin-password" # pragma: allowlist secret
      }]
      fqdn         = "aks.example.com"
      private_fqdn = "aks.private.example.com"
    }
  }
  assert {
    condition = (
      output.kube_config == "test-kubeconfig-yaml" &&
      output.kube_config == output.kube_config_raw &&
      output.host == "https://aks.example.com" &&
      base64decode(output.client_certificate) == "test-cert" &&   # pragma: allowlist secret
      base64decode(output.client_key) == "test-key" &&            # pragma: allowlist secret
      base64decode(output.cluster_ca_certificate) == "test-ca" && # pragma: allowlist secret
      output.username == "test-user" &&
      output.password == "test-password" && # pragma: allowlist secret
      output.kube_config_credentials.client_key == output.client_key &&
      output.kube_admin_config_credentials.username == "admin-user" &&
      output.kube_admin_config_raw == "test-admin-yaml" &&
      output.fqdn == "aks.example.com" &&
      output.private_fqdn == "aks.private.example.com"
    )
    error_message = "Connection outputs must preserve user credentials, admin credentials, raw YAML, and DNS names independently."
  }
}

