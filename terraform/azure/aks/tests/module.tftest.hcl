mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-resource"
    }
  }
}

variables {
  name                = "test-resource"
  resource_group_name = "rg-test"
  location            = "uksouth"
  dns_prefix          = "test-aks"
}

run "private_cluster_defaults" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.private_cluster_enabled && azurerm_kubernetes_cluster.this.workload_identity_enabled
    error_message = "The cluster must default to a private endpoint with workload identity."
  }
}

run "entra_disables_local_accounts" {
  command = plan
  variables {
    admin_group_object_ids = ["11111111-1111-1111-1111-111111111111"]
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.local_account_disabled && azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control[0].azure_rbac_enabled
    error_message = "Entra integration must enable Azure RBAC and disable local accounts."
  }
}

run "user_assigned_identity" {
  command = plan
  variables {
    identity_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test"]
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.identity[0].type == "UserAssigned"
    error_message = "Supplied identity IDs must select user-assigned identity mode."
  }
}

run "reject_workload_identity_without_oidc" {
  command = plan
  variables {
    oidc_issuer_enabled = false
  }
  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "reject_fractional_node_count" {
  command = plan
  variables {
    node_count = 1.5
  }
  expect_failures = [var.node_count]
}

run "addons_disabled_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_kubernetes_cluster_extension.argocd) == 0 && length(azurerm_kubernetes_cluster.this.web_app_routing) == 0 && length(azurerm_kubernetes_cluster.this.monitor_metrics) == 0
    error_message = "Argo CD, routing, and metrics must remain opt-in."
  }
}

run "configured_cluster" {
  command = plan
  variables {
    auto_scaling_enabled        = true
    min_count                   = 3
    max_count                   = 5
    max_pods                    = 30
    node_public_ip_enabled      = true
    temporary_name_for_rotation = "rotatingpool"
    tenant_id                   = "11111111-1111-1111-1111-111111111111"
    admin_group_object_ids      = ["22222222-2222-2222-2222-222222222222"]
    local_account_disabled      = false
    monitor_metrics = {
      annotations_allowed = "prometheus.io/scrape,prometheus.io/port,prometheus.io/path"
      labels_allowed      = "app,app.kubernetes.io/name"
    }
    web_app_routing = {
      dns_zone_ids             = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/dnsZones/example.com"]
      default_nginx_controller = "External"
    }
    argocd = {
      namespace              = "gitops"
      namespace_install      = true
      configuration_settings = { "configs.cm.url" = "https://argocd.example.com" }
    }
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].auto_scaling_enabled && azurerm_kubernetes_cluster.this.default_node_pool[0].min_count == 3 && azurerm_kubernetes_cluster.this.default_node_pool[0].max_count == 5 && azurerm_kubernetes_cluster.this.default_node_pool[0].max_pods == 30
    error_message = "The node pool must use the supplied autoscaling limits and pod capacity."
  }
  assert {
    condition     = !azurerm_kubernetes_cluster.this.local_account_disabled && azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control[0].tenant_id == var.tenant_id
    error_message = "Explicit local account and tenant settings must override inferred defaults."
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.monitor_metrics[0].annotations_allowed == var.monitor_metrics.annotations_allowed && azurerm_kubernetes_cluster.this.web_app_routing[0].dns_zone_ids == var.web_app_routing.dns_zone_ids
    error_message = "Metrics and application routing must use the requested settings."
  }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.argocd[0].release_namespace == "gitops" && azurerm_kubernetes_cluster_extension.argocd[0].configuration_settings["namespaceInstall"] == "true" && azurerm_kubernetes_cluster_extension.argocd[0].configuration_settings["deployWithHighAvailability"] == "false" && azurerm_kubernetes_cluster_extension.argocd[0].configuration_settings["redis-ha.enabled"] == "false"
    error_message = "Argo CD must use the requested namespace and explicitly disable HA."
  }
}

run "argocd_ha_with_autoscaling" {
  command = plan
  variables {
    auto_scaling_enabled = true
    min_count            = 4
    max_count            = 5
    argocd               = { high_availability = true }
  }
  assert {
    condition     = azurerm_kubernetes_cluster_extension.argocd[0].configuration_settings["deployWithHighAvailability"] == "true"
    error_message = "Argo CD HA must be enabled when four nodes are guaranteed."
  }
}

run "reject_argocd_ha_with_three_nodes" {
  command = plan
  variables {
    node_count = 3
    argocd     = { high_availability = true }
  }
  expect_failures = [azurerm_kubernetes_cluster_extension.argocd]
}

run "reject_argocd_ha_with_low_autoscaling_minimum" {
  command = plan
  variables {
    node_count           = 4
    auto_scaling_enabled = true
    min_count            = 3
    max_count            = 5
    argocd               = { high_availability = true }
  }
  expect_failures = [azurerm_kubernetes_cluster_extension.argocd]
}

run "reject_reversed_scaling_limits" {
  command = plan
  variables {
    auto_scaling_enabled = true
    min_count            = 5
    max_count            = 3
  }
  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "reject_disabled_accounts_without_entra" {
  command = plan
  variables {
    local_account_disabled = true
  }
  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "reject_invalid_namespace" {
  command = plan
  variables {
    argocd = { namespace = "Invalid_Namespace" }
  }
  expect_failures = [var.argocd]
}
