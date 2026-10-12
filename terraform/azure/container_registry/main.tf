locals {
  name = coalesce(var.name, "${replace(lower(var.settings.name_prefix), "/[^a-z0-9]/", "")}acr")
}

resource "azurerm_container_registry" "this" {
  name                          = local.name
  resource_group_name           = var.resource_group_name
  location                      = var.settings.region_long
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option
  data_endpoint_enabled         = var.data_endpoint_enabled
  export_policy_enabled         = var.export_policy_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  tags                          = var.tags

  network_rule_set = var.network_rule_set == null ? [] : [{
    default_action = var.network_rule_set.default_action
    ip_rule = [for ip_range in var.network_rule_set.ip_ranges : {
      action   = "Allow"
      ip_range = ip_range
    }]
  }]

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                        = georeplications.value.location
      zone_redundancy_enabled         = georeplications.value.zone_redundancy_enabled
      global_endpoint_routing_enabled = georeplications.value.global_endpoint_routing_enabled
      tags                            = georeplications.value.tags
    }
  }

  lifecycle {
    precondition {
      condition     = can(regex("^[A-Za-z0-9]{5,50}$", local.name))
      error_message = "The resolved registry name must contain 5 to 50 letters or digits. Set name to override an invalid generated name."
    }

    precondition {
      condition     = var.sku == "Premium" || (var.network_rule_set == null && length(var.georeplications) == 0 && !var.data_endpoint_enabled && !var.zone_redundancy_enabled && var.export_policy_enabled)
      error_message = "Network rules, georeplications, dedicated data endpoints, zone redundancy, and disabling exports require the Premium SKU."
    }

    precondition {
      condition     = !var.anonymous_pull_enabled || var.sku != "Basic"
      error_message = "Anonymous pull requires the Standard or Premium SKU."
    }

    precondition {
      condition     = var.export_policy_enabled || !var.public_network_access_enabled
      error_message = "Disabling exports requires public network access to be disabled."
    }

    precondition {
      condition     = alltrue([for replica in var.georeplications : lower(replica.location) != lower(var.settings.region_long)])
      error_message = "Georeplication locations must differ from settings.region_long."
    }
  }
}
