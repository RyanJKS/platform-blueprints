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
    default_node_pool = {
      node_count = 1.5
    }
  }
  expect_failures = [var.default_node_pool]
}

run "addons_disabled_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_kubernetes_cluster.this.web_app_routing) == 0 && length(azurerm_kubernetes_cluster.this.monitor_metrics) == 0
    error_message = "Routing and metrics must remain opt-in."
  }
}

run "configured_cluster" {
  command = plan
  variables {
    default_node_pool = {
      auto_scaling_enabled        = true
      min_count                   = 3
      max_count                   = 5
      max_pods                    = 30
      node_public_ip_enabled      = true
      temporary_name_for_rotation = "rotatingpool"
    }
    tenant_id              = "11111111-1111-1111-1111-111111111111"
    admin_group_object_ids = ["22222222-2222-2222-2222-222222222222"]
    local_account_disabled = false
    monitor_metrics = {
      annotations_allowed = "prometheus.io/scrape,prometheus.io/port,prometheus.io/path"
      labels_allowed      = "app,app.kubernetes.io/name"
    }
    web_app_routing = {
      dns_zone_ids             = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/dnsZones/example.com"]
      default_nginx_controller = "External"
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

}

run "reject_reversed_scaling_limits" {
  command = plan
  variables {
    default_node_pool = {
      auto_scaling_enabled = true
      min_count            = 5
      max_count            = 3
    }
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


run "fixed_capacity_output" {
  command = plan
  assert {
    condition     = output.minimum_node_count == 2
    error_message = "Fixed capacity must expose node_count."
  }
}
run "autoscaling_capacity_output" {
  command = plan
  variables {
    default_node_pool = {
      auto_scaling_enabled = true
      node_count           = 2
      min_count            = 4
    }
  }
  assert {
    condition     = output.minimum_node_count == 4
    error_message = "Autoscaling capacity must expose min_count, not node_count."
  }
}

run "partial_node_pool_override" {
  command = plan
  variables {
    default_node_pool = {
      name       = "workers"
      node_count = 4
      vm_size    = "Standard_D4s_v5"
    }
  }
  assert {
    condition = (
      azurerm_kubernetes_cluster.this.default_node_pool[0].name == "workers" &&
      azurerm_kubernetes_cluster.this.default_node_pool[0].node_count == 4 &&
      azurerm_kubernetes_cluster.this.default_node_pool[0].vm_size == "Standard_D4s_v5" &&
      !azurerm_kubernetes_cluster.this.default_node_pool[0].auto_scaling_enabled &&
      !azurerm_kubernetes_cluster.this.default_node_pool[0].node_public_ip_enabled &&
      azurerm_kubernetes_cluster.this.default_node_pool[0].temporary_name_for_rotation == "rotatingpool" &&
      output.minimum_node_count == 4
    )
    error_message = "Partial overrides must preserve defaults for omitted attributes and update fixed capacity."
  }
}

run "null_node_pool_uses_defaults" {
  command = plan
  variables {
    default_node_pool = null
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].name == "system" && output.minimum_node_count == 2
    error_message = "A null node pool must use the module defaults."
  }
}

run "null_attributes_use_defaults" {
  command = plan
  variables {
    default_node_pool = {
      name                 = null
      node_count           = null
      auto_scaling_enabled = null
      max_pods             = null
    }
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].name == "system" && output.minimum_node_count == 2 && !azurerm_kubernetes_cluster.this.default_node_pool[0].auto_scaling_enabled
    error_message = "Explicit null attributes must retain non-null defaults."
  }
}
