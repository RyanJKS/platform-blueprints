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


run "configured_integrations" {
  command = plan
  variables {
    dns_prefix                 = null
    dns_prefix_private_cluster = "aks-01"
    private_dns_zone_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.uksouth.azmk8s.io"
    identity_ids               = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/controlplane"]
    kubelet_identity = {
      client_id                 = "11111111-1111-1111-1111-111111111111"
      object_id                 = "22222222-2222-2222-2222-222222222222"
      user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/kubelet"
    }
    network_profile = {
      network_plugin = "azure"
      dns_service_ip = "10.1.3.4"
      service_cidr   = "10.1.3.0/24"
    }
    ingress_application_gateway = {
      gateway_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationGateways/example"
    }
    key_management_service = {
      key_vault_key_id         = "https://example.vault.azure.net/keys/kms/0123456789abcdef0123456789abcdef"
      key_vault_network_access = "Private"
    }
    oms_agent = {
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/example"
    }
    admin_group_object_ids = ["33333333-3333-3333-3333-333333333333"]
    local_account_disabled = true
    sku_tier               = "Standard"
  }
  assert {
    condition = (
      azurerm_kubernetes_cluster.this.dns_prefix_private_cluster == "aks-01" &&
      azurerm_kubernetes_cluster.this.private_dns_zone_id == var.private_dns_zone_id &&
      azurerm_kubernetes_cluster.this.identity[0].type == "UserAssigned" &&
      azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id == var.kubelet_identity.client_id &&
      azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id == var.kubelet_identity.object_id &&
      azurerm_kubernetes_cluster.this.kubelet_identity[0].user_assigned_identity_id == var.kubelet_identity.user_assigned_identity_id &&
      azurerm_kubernetes_cluster.this.network_profile[0].network_plugin == "azure" &&
      azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip == "10.1.3.4" &&
      azurerm_kubernetes_cluster.this.network_profile[0].service_cidr == "10.1.3.0/24" &&
      azurerm_kubernetes_cluster.this.ingress_application_gateway[0].gateway_id == var.ingress_application_gateway.gateway_id &&
      azurerm_kubernetes_cluster.this.key_management_service[0].key_vault_key_id == var.key_management_service.key_vault_key_id &&
      azurerm_kubernetes_cluster.this.key_management_service[0].key_vault_network_access == "Private" &&
      azurerm_kubernetes_cluster.this.oms_agent[0].log_analytics_workspace_id == var.oms_agent.log_analytics_workspace_id &&
      azurerm_kubernetes_cluster.this.oms_agent[0].msi_auth_for_monitoring_enabled
    )
    error_message = "Private DNS, identities, networking, ingress, KMS, and monitoring must preserve caller settings."
  }
}

run "new_addons_disabled_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_kubernetes_cluster.this.ingress_application_gateway) == 0 && length(azurerm_kubernetes_cluster.this.key_management_service) == 0 && length(azurerm_kubernetes_cluster.this.oms_agent) == 0
    error_message = "New addons must remain opt-in."
  }
}

run "reject_both_dns_prefixes" {
  command = plan
  variables {
    dns_prefix_private_cluster = "private"
  }
  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "reject_no_dns_prefix" {
  command = plan
  variables {
    dns_prefix = null
  }
  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "reject_kubelet_without_controlplane_identity" {
  command = plan
  variables {
    kubelet_identity = {
      client_id                 = "11111111-1111-1111-1111-111111111111"
      object_id                 = "22222222-2222-2222-2222-222222222222"
      user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/kubelet"
    }
  }
  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "reject_invalid_kms_access" {
  command = plan
  variables {
    key_management_service = { key_vault_key_id = "https://example.vault.azure.net/keys/kms", key_vault_network_access = "Invalid" }
  }
  expect_failures = [var.key_management_service]
}

run "existing_network_defaults" {
  command = plan
  assert {
    condition     = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin == "azure" && azurerm_kubernetes_cluster.this.network_profile[0].network_plugin_mode == "overlay" && azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku == "standard"
    error_message = "Omitting the network profile must preserve Azure CNI overlay defaults."
  }
}
