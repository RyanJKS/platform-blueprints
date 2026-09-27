locals {
  name     = coalesce(var.name, "${var.settings.name_prefix}agw")
  location = coalesce(var.location, var.settings.region_long)
}

resource "azurerm_application_gateway" "this" {
  name                = local.name
  location            = local.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  zones               = var.zones
  http2_enabled       = var.http2_enabled
  firewall_policy_id  = var.firewall_policy_id

  sku {
    name     = var.sku.tier
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }
  gateway_ip_configuration {
    name      = "gateway"
    subnet_id = var.subnet_id
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = var.ssl_policy_name
  }
  dynamic "identity" {
    for_each = length(var.identity_ids) == 0 ? [] : [var.identity_ids]
    content {
      type         = "UserAssigned"
      identity_ids = identity.value
    }
  }
  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration == null ? [] : [var.autoscale_configuration]
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }
  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                          = frontend_ip_configuration.key
      public_ip_address_id          = frontend_ip_configuration.value.public_ip_address_id
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address == null ? "Dynamic" : "Static"
      subnet_id                     = frontend_ip_configuration.value.private_ip_address == null ? null : var.subnet_id
    }
  }
  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.key
      port = frontend_port.value
    }
  }
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.key
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.key
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      request_timeout                     = backend_http_settings.value.request_timeout
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      path                                = backend_http_settings.value.path
      probe_name                          = backend_http_settings.value.probe_name
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names
      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining == null ? [] : [backend_http_settings.value.connection_draining]
        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.key
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
    }
  }
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = request_routing_rule.key
      priority                   = request_routing_rule.value.priority
      http_listener_name         = request_routing_rule.value.http_listener_name
      rule_type                  = request_routing_rule.value.rule_type
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      url_path_map_name          = request_routing_rule.value.url_path_map_name
    }
  }
  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = probe.key
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = probe.value.host
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      port                                      = probe.value.port
      dynamic "match" {
        for_each = probe.value.match == null ? [] : [probe.value.match]
        content {
          status_code = match.value.status_code
          body        = match.value.body
        }
      }
    }
  }
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.key
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }
  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificates
    content {
      name = trusted_root_certificate.key
      data = trusted_root_certificate.value
    }
  }
  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                               = url_path_map.key
      default_backend_address_pool_name  = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name = url_path_map.value.default_backend_http_settings_name
      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = path_rule.value.name
          paths                      = path_rule.value.paths
          backend_address_pool_name  = path_rule.value.backend_address_pool_name
          backend_http_settings_name = path_rule.value.backend_http_settings_name
        }
      }
    }
  }
  lifecycle {
    precondition {
      condition     = length(var.ssl_certificates) == 0 || length(var.identity_ids) > 0
      error_message = "Key Vault certificates require a user-assigned identity in identity_ids."
    }
    precondition {
      condition     = var.sku.tier == "WAF_v2" ? var.firewall_policy_id != null : var.firewall_policy_id == null
      error_message = "WAF_v2 requires an existing firewall_policy_id; Standard_v2 must not specify one."
    }
    precondition {
      condition = alltrue([for l in values(var.http_listeners) :
        contains(keys(var.frontend_ip_configurations), l.frontend_ip_configuration_name) &&
        contains(keys(var.frontend_ports), l.frontend_port_name) &&
        (l.ssl_certificate_name == null ? true : contains(keys(var.ssl_certificates), l.ssl_certificate_name))
      ])
      error_message = "Listeners must reference frontend configurations, ports, and certificates declared in this module."
    }
    precondition {
      condition = alltrue([for b in values(var.backend_http_settings) :
        (b.probe_name == null ? true : contains(keys(var.probes), b.probe_name)) &&
        alltrue([for name in b.trusted_root_certificate_names : contains(keys(var.trusted_root_certificates), name)])
      ])
      error_message = "Backend settings must reference declared probes and trusted root certificates."
    }
    precondition {
      condition = alltrue([for r in values(var.request_routing_rules) :
        contains(keys(var.http_listeners), r.http_listener_name) &&
        (r.rule_type == "Basic" ? (
          contains(keys(var.backend_address_pools), coalesce(r.backend_address_pool_name, "__missing__")) && contains(keys(var.backend_http_settings), coalesce(r.backend_http_settings_name, "__missing__"))
        ) : contains(keys(var.url_path_maps), coalesce(r.url_path_map_name, "__missing__")))
      ])
      error_message = "Routing rules must reference declared listeners, backend pools/settings, and path maps."
    }
    precondition {
      condition = alltrue([for m in values(var.url_path_maps) :
        contains(keys(var.backend_address_pools), m.default_backend_address_pool_name) && contains(keys(var.backend_http_settings), m.default_backend_http_settings_name) &&
        length(m.path_rules) > 0 && alltrue([for r in m.path_rules : contains(keys(var.backend_address_pools), r.backend_address_pool_name) && contains(keys(var.backend_http_settings), r.backend_http_settings_name)])
      ])
      error_message = "Path maps require path rules and valid default and per-path backend references."
    }
  }
}
