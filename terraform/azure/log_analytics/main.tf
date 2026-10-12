locals {
  name     = coalesce(var.name, "${var.settings.name_prefix}law")
  location = coalesce(var.location, var.settings.region_long)
}

resource "azurerm_log_analytics_workspace" "this" {
  name                               = local.name
  resource_group_name                = var.resource_group_name
  location                           = local.location
  sku                                = var.sku
  reservation_capacity_in_gb_per_day = var.reservation_capacity_in_gb_per_day
  retention_in_days                  = var.retention_in_days
  daily_quota_gb                     = var.daily_quota_gb
  local_authentication_enabled       = var.local_authentication_enabled
  allow_resource_only_permissions    = var.allow_resource_only_permissions
  internet_ingestion_access_type     = var.internet_ingestion_access_type
  internet_query_access_type         = var.internet_query_access_type
  tags                               = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{2,61}[A-Za-z0-9]$", local.name))
      error_message = "The resolved workspace name must contain 4 to 63 letters, digits, or hyphens, and must start and end with a letter or digit. Set name to override an invalid generated name."
    }

    precondition {
      condition     = var.sku == "CapacityReservation" ? var.reservation_capacity_in_gb_per_day != null : var.reservation_capacity_in_gb_per_day == null
      error_message = "reservation_capacity_in_gb_per_day must be set only when sku is CapacityReservation, and is required for that SKU."
    }
  }
}
