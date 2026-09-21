locals {
  entra_enabled = length(var.admin_group_object_ids) > 0 || var.tenant_id != null
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  private_cluster_enabled           = var.private_cluster_enabled
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  workload_identity_enabled         = var.workload_identity_enabled
  sku_tier                          = var.sku_tier
  role_based_access_control_enabled = true
  local_account_disabled            = var.local_account_disabled != null ? var.local_account_disabled : local.entra_enabled
  tags                              = var.tags

  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name                        = var.default_node_pool.name
    node_count                  = var.default_node_pool.auto_scaling_enabled ? null : var.default_node_pool.node_count
    auto_scaling_enabled        = var.default_node_pool.auto_scaling_enabled
    min_count                   = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.min_count : null
    max_count                   = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.max_count : null
    max_pods                    = var.default_node_pool.max_pods
    node_public_ip_enabled      = var.default_node_pool.node_public_ip_enabled
    temporary_name_for_rotation = var.default_node_pool.temporary_name_for_rotation
    zones                       = var.default_node_pool.zones
    os_disk_size_gb             = var.default_node_pool.os_disk_size_gb
    vm_size                     = var.default_node_pool.vm_size
    vnet_subnet_id              = var.default_node_pool.vnet_subnet_id
  }

  identity {
    type         = length(var.identity_ids) > 0 ? "UserAssigned" : "SystemAssigned"
    identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : null
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = local.entra_enabled ? [true] : []

    content {
      admin_group_object_ids = var.admin_group_object_ids
      azure_rbac_enabled     = var.azure_rbac_enabled
      tenant_id              = var.tenant_id
    }
  }

  dynamic "monitor_metrics" {
    for_each = var.monitor_metrics == null ? [] : [var.monitor_metrics]
    content {
      annotations_allowed = monitor_metrics.value.annotations_allowed
      labels_allowed      = monitor_metrics.value.labels_allowed
    }
  }

  dynamic "web_app_routing" {
    for_each = var.web_app_routing == null ? [] : [var.web_app_routing]
    content {
      dns_zone_ids             = web_app_routing.value.dns_zone_ids
      default_nginx_controller = web_app_routing.value.default_nginx_controller
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
  }

  lifecycle {
    precondition {
      condition     = !var.default_node_pool.auto_scaling_enabled || var.default_node_pool.min_count <= var.default_node_pool.max_count
      error_message = "Autoscaling min_count must not exceed max_count."
    }
    precondition {
      condition     = var.local_account_disabled != true || local.entra_enabled
      error_message = "Disabling local accounts requires Entra integration through admin_group_object_ids or tenant_id."
    }
    precondition {
      condition     = !var.workload_identity_enabled || var.oidc_issuer_enabled
      error_message = "Workload identity requires the OIDC issuer to be enabled."
    }
  }
}
