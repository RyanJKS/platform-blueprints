mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test" }
  }
}

variables {
  settings = {
    name_prefix = "test"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
  resource_group_name = "rg-test"
  dns_prefix          = "test"
}

run "no_additional_pools_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_kubernetes_cluster_node_pool.this) == 0
    error_message = "Additional pools must remain opt-in."
  }
}

run "mixed_workloads" {
  command = plan
  variables {
    default_node_pool = {
      vm_size        = "Standard_D4s_v5"
      node_count     = 3
      vnet_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/test/subnets/aks"
    }
    additional_node_pools = {
      general = { vm_size = "Standard_D8s_v5", min_count = 3, max_count = 20, max_surge = "20%", temporary_name_for_rotation = "generaltemp" }
      memory  = { vm_size = "Standard_E16s_v5", min_count = 1, max_count = 10, max_unavailable = "1", node_labels = { workload = "memory" }, node_taints = ["workload=memory:NoSchedule"] }
      gpu     = { vm_size = "Standard_NC24ads_A100_v4", min_count = 0, max_count = 5, node_taints = ["sku=gpu:NoSchedule"] }
      spot    = { vm_size = "Standard_D8s_v5", min_count = 0, max_count = 20, priority = "Spot" }
    }
  }
  assert {
    condition = (
      azurerm_kubernetes_cluster.this.default_node_pool[0].node_count == 3 &&
      length(azurerm_kubernetes_cluster_node_pool.this) == 4 &&
      azurerm_kubernetes_cluster_node_pool.this["general"].vnet_subnet_id == var.default_node_pool.vnet_subnet_id &&
      azurerm_kubernetes_cluster_node_pool.this["general"].upgrade_settings[0].max_surge == "20%" &&
      azurerm_kubernetes_cluster_node_pool.this["memory"].upgrade_settings[0].max_surge == null &&
      azurerm_kubernetes_cluster_node_pool.this["memory"].upgrade_settings[0].max_unavailable == "1" &&
      azurerm_kubernetes_cluster_node_pool.this["memory"].node_labels["workload"] == "memory" &&
      azurerm_kubernetes_cluster_node_pool.this["gpu"].min_count == 0 &&
      azurerm_kubernetes_cluster_node_pool.this["gpu"].node_count == 0 &&
      azurerm_kubernetes_cluster_node_pool.this["spot"].priority == "Spot" &&
      azurerm_kubernetes_cluster_node_pool.this["spot"].eviction_policy == "Delete" &&
      azurerm_kubernetes_cluster_node_pool.this["spot"].spot_max_price == -1 &&
      length(azurerm_kubernetes_cluster_node_pool.this["spot"].upgrade_settings) == 0 &&
      output.minimum_node_count == 3
    )
    error_message = "Mixed workloads must preserve capacity, scheduling, subnet inheritance, and Spot semantics."
  }
}

run "reject_invalid_counts" {
  command = plan
  variables {
    additional_node_pools = { general = { vm_size = "Standard_D8s_v5", min_count = 5, max_count = 3 } }
  }
  expect_failures = [var.additional_node_pools]
}

run "reject_duplicate_system_name" {
  command = plan
  variables {
    additional_node_pools = { system = { vm_size = "Standard_D8s_v5", min_count = 0, max_count = 3 } }
  }
  expect_failures = [azurerm_kubernetes_cluster_node_pool.this]
}

run "reject_conflicting_upgrade_settings" {
  command = plan
  variables {
    additional_node_pools = { general = { vm_size = "Standard_D8s_v5", min_count = 0, max_count = 3, max_surge = "10%", max_unavailable = "1" } }
  }
  expect_failures = [var.additional_node_pools]
}

run "reject_rotation_collision" {
  command = plan
  variables {
    additional_node_pools = { general = { vm_size = "Standard_D8s_v5", min_count = 0, max_count = 3, temporary_name_for_rotation = "system" } }
  }
  expect_failures = [azurerm_kubernetes_cluster_node_pool.this]
}
