locals {
  name          = coalesce(var.name, "${var.settings.name_prefix}aks")
  location      = coalesce(var.location, var.settings.region_long)
  tenant_id     = coalesce(var.tenant_id, var.settings.tenant_id)
  entra_enabled = length(var.admin_group_object_ids) > 0 || var.tenant_id != null
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = local.name
  resource_group_name               = var.resource_group_name
  location                          = local.location
  dns_prefix                        = var.dns_prefix
  dns_prefix_private_cluster        = var.dns_prefix_private_cluster
  private_dns_zone_id               = var.private_dns_zone_id
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
      tenant_id              = local.tenant_id
    }
  }

  dynamic "kubelet_identity" {
    for_each = var.kubelet_identity == null ? [] : [var.kubelet_identity]
    content {
      client_id                 = kubelet_identity.value.client_id
      object_id                 = kubelet_identity.value.object_id
      user_assigned_identity_id = kubelet_identity.value.user_assigned_identity_id
    }
  }

  dynamic "network_profile" {
    for_each = var.network_profile == null ? [] : [var.network_profile]
    content {
      network_plugin      = network_profile.value.network_plugin
      network_plugin_mode = network_profile.value.network_plugin_mode
      network_policy      = network_profile.value.network_policy
      network_data_plane  = network_profile.value.network_data_plane
      dns_service_ip      = network_profile.value.dns_service_ip
      service_cidr        = network_profile.value.service_cidr
      pod_cidr            = network_profile.value.pod_cidr
      outbound_type       = network_profile.value.outbound_type
      load_balancer_sku   = network_profile.value.load_balancer_sku
    }
  }

  dynamic "ingress_application_gateway" {
    for_each = var.ingress_application_gateway == null ? [] : [var.ingress_application_gateway]
    content {
      gateway_id = ingress_application_gateway.value.gateway_id
    }
  }

  dynamic "key_management_service" {
    for_each = var.key_management_service == null ? [] : [var.key_management_service]
    content {
      key_vault_key_id         = key_management_service.value.key_vault_key_id
      key_vault_network_access = key_management_service.value.key_vault_network_access
    }
  }

  dynamic "oms_agent" {
    for_each = var.oms_agent == null ? [] : [var.oms_agent]
    content {
      log_analytics_workspace_id      = oms_agent.value.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = oms_agent.value.msi_auth_for_monitoring_enabled
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

  lifecycle {
    precondition {
      condition     = (var.dns_prefix != null) != (var.dns_prefix_private_cluster != null)
      error_message = "Set exactly one of dns_prefix or dns_prefix_private_cluster."
    }
    precondition {
      condition     = var.dns_prefix_private_cluster == null || (var.private_cluster_enabled && var.private_dns_zone_id != null && !contains(["System", "None"], coalesce(var.private_dns_zone_id, "System")))
      error_message = "dns_prefix_private_cluster requires a private cluster and a custom private_dns_zone_id."
    }
    precondition {
      condition     = var.kubelet_identity == null || length(var.identity_ids) > 0
      error_message = "A custom kubelet_identity requires a user-assigned control-plane identity in identity_ids."
    }

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
