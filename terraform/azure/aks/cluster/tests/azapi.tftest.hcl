mock_provider "azapi" {}
mock_provider "tls" {}
mock_provider "random" {}
mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test"
    }
  }
  mock_resource "azurerm_kubernetes_cluster_node_pool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test/agentPools/workloads"
    }
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
  key_vault_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/test"
}

run "overrides_are_opt_in" {
  command = plan

  assert {
    condition     = length(azapi_update_resource.kube_proxy_disabled) == 0 && length(azapi_update_resource.localdns) == 0
    error_message = "Default networking must not create API overrides."
  }
}

run "managed_cilium_needs_no_override" {
  command = plan

  variables {
    network_profile = {
      network_plugin      = "azure"
      network_plugin_mode = "overlay"
      network_data_plane  = "cilium"
    }
  }

  assert {
    condition     = length(azapi_update_resource.kube_proxy_disabled) == 0
    error_message = "AKS-managed Cilium must work without an explicit kube-proxy override."
  }
}

run "disable_proxy_and_enable_localdns" {
  command = apply

  variables {
    kube_proxy_disabled = true
    network_profile = {
      network_plugin = "none"
    }
    additional_node_pools = {
      workloads = { vm_size = "Standard_D8s_v5", min_count = 1, max_count = 3 }
      general   = { vm_size = "Standard_D8s_v5", min_count = 1, max_count = 3 }
    }
    local_dns_profiles = {
      workloads = {
        mode = "Required"
        vnetDNSOverrides = {
          "." = {
            protocol           = "ForceTCP"
            forwardDestination = "VnetDNS"
          }
        }
        kubeDNSOverrides = {
          "cluster.local" = {
            protocol           = "ForceTCP"
            forwardDestination = "ClusterCoreDNS"
          }
        }
      }
    }
  }

  assert {
    condition = (
      !azapi_update_resource.kube_proxy_disabled[0].body.properties.networkProfile.kubeProxyConfig.enabled &&
      azapi_update_resource.kube_proxy_disabled[0].resource_id == azurerm_kubernetes_cluster.this.id
    )
    error_message = "The override must disable kube-proxy on this cluster."
  }

  assert {
    condition = (
      length(azapi_update_resource.localdns) == 1 &&
      azapi_update_resource.localdns["workloads"].resource_id == azurerm_kubernetes_cluster_node_pool.this["workloads"].id &&
      azapi_update_resource.localdns["workloads"].body.properties.localDNSProfile.mode == "Required" &&
      azapi_update_resource.localdns["workloads"].body.properties.localDNSProfile.vnetDNSOverrides["."].protocol == "ForceTCP" &&
      azapi_update_resource.localdns["workloads"].body.properties.localDNSProfile.kubeDNSOverrides["cluster.local"].forwardDestination == "ClusterCoreDNS"
    )
    error_message = "LocalDNS must target only the selected pool and preserve nested API properties."
  }
}

run "restore_proxy_and_disable_localdns" {
  command = apply

  variables {
    kube_proxy_disabled = false
    network_profile = {
      network_plugin = "none"
    }
    additional_node_pools = {
      workloads = { vm_size = "Standard_D8s_v5", min_count = 1, max_count = 3 }
      general   = { vm_size = "Standard_D8s_v5", min_count = 1, max_count = 3 }
    }
    local_dns_profiles = {
      workloads = { mode = "Disabled" }
    }
  }

  assert {
    condition = (
      length(azapi_update_resource.kube_proxy_disabled) == 1 &&
      azapi_update_resource.kube_proxy_disabled[0].body.properties.networkProfile.kubeProxyConfig.enabled &&
      azapi_update_resource.localdns["workloads"].body.properties.localDNSProfile.mode == "Disabled"
    )
    error_message = "Explicit settings must update existing overrides rather than only removing them from state."
  }
}

run "reject_proxy_override_for_managed_cilium" {
  command = plan

  variables {
    kube_proxy_disabled = false
    network_profile = {
      network_plugin      = "azure"
      network_plugin_mode = "overlay"
      network_data_plane  = "cilium"
    }
  }

  expect_failures = [azapi_update_resource.kube_proxy_disabled]
}

run "reject_disablement_without_byo_cni" {
  command = plan

  variables {
    kube_proxy_disabled = true
  }

  expect_failures = [azapi_update_resource.kube_proxy_disabled]
}

run "reject_unknown_localdns_pool" {
  command = plan

  variables {
    local_dns_profiles = {
      missing = { mode = "Required" }
    }
  }

  expect_failures = [azapi_update_resource.localdns]
}

run "reject_invalid_localdns_mode" {
  command = plan

  variables {
    local_dns_profiles = {
      workloads = { mode = "Enabled" }
    }
  }

  expect_failures = [var.local_dns_profiles]
}
