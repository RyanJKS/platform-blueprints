resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.additional_node_pools

  kubernetes_cluster_id       = azurerm_kubernetes_cluster.this.id
  name                        = each.key
  mode                        = "User"
  orchestrator_version        = var.kubernetes_version
  vnet_subnet_id              = each.value.vnet_subnet_id != null ? each.value.vnet_subnet_id : var.default_node_pool.vnet_subnet_id
  vm_size                     = each.value.vm_size
  zones                       = each.value.zones
  auto_scaling_enabled        = true
  min_count                   = each.value.min_count
  max_count                   = each.value.max_count
  node_count                  = each.value.min_count
  max_pods                    = each.value.max_pods
  os_disk_type                = each.value.os_disk_type
  os_disk_size_gb             = each.value.os_disk_size_gb
  node_labels                 = each.value.node_labels
  node_taints                 = each.value.node_taints
  fips_enabled                = each.value.fips_enabled
  host_encryption_enabled     = each.value.host_encryption_enabled
  temporary_name_for_rotation = each.value.temporary_name_for_rotation
  priority                    = each.value.priority
  eviction_policy             = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price              = each.value.priority == "Spot" ? each.value.spot_max_price : null
  tags                        = var.tags

  dynamic "upgrade_settings" {
    for_each = each.value.priority == "Regular" ? [each.value] : []
    content {
      drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
      max_surge                     = upgrade_settings.value.max_unavailable == null ? coalesce(upgrade_settings.value.max_surge, "10%") : null
      max_unavailable               = upgrade_settings.value.max_unavailable
      node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
      undrainable_node_behavior     = upgrade_settings.value.undrainable_node_behavior
    }
  }

  lifecycle {
    # The autoscaler owns capacity. AKS/Fleet owns subsequent version upgrades.
    ignore_changes = [node_count, orchestrator_version, workload_runtime]

    precondition {
      condition     = each.key != var.default_node_pool.name && each.key != var.default_node_pool.temporary_name_for_rotation
      error_message = "Additional pool names must not collide with the default pool or its rotation name."
    }
    precondition {
      condition = each.value.temporary_name_for_rotation == null ? true : (
        !contains(concat(keys(var.additional_node_pools), [var.default_node_pool.name, var.default_node_pool.temporary_name_for_rotation]), each.value.temporary_name_for_rotation) &&
        length([for pool in values(var.additional_node_pools) : pool.temporary_name_for_rotation if pool.temporary_name_for_rotation == each.value.temporary_name_for_rotation]) == 1
      )
      error_message = "Rotation names must be unique and must not match any configured pool name or the default rotation name."
    }
  }
}
