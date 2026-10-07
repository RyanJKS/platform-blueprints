variable "settings" {
  description = "Shared naming and region defaults. Explicit inputs take precedence."
  type        = object({ name_prefix = string, region_long = string })
  nullable    = false
}
variable "name" {
  description = "Name override. Defaults to settings.name_prefix followed by agw."
  type        = string
  default     = null
}
variable "location" {
  description = "Region override. Defaults to settings.region_long."
  type        = string
  default     = null
}
variable "resource_group_name" {
  description = "The existing resource group name."
  type        = string
  nullable    = false
}
variable "subnet_id" {
  description = "The dedicated Application Gateway subnet resource ID."
  type        = string
  nullable    = false
}
variable "tags" {
  description = "Tags for the gateway and the optional managed public IP."
  type        = map(string)
  default     = {}
  nullable    = false
}
variable "sku" {
  description = "Application Gateway v2 SKU and fixed capacity. Capacity is omitted when autoscaling is configured."
  type        = object({ tier = optional(string, "Standard_v2"), capacity = optional(number, 2) })
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku.tier) && var.sku.capacity >= 1 && var.sku.capacity <= 125 && floor(var.sku.capacity) == var.sku.capacity
    error_message = "SKU must be Standard_v2 or WAF_v2 with integer capacity from 1 to 125."
  }
}
variable "autoscale_configuration" {
  description = "Optional autoscaling bounds. Null uses fixed SKU capacity."
  type        = object({ min_capacity = optional(number, 2), max_capacity = optional(number, 10) })
  default     = null
  validation {
    condition = var.autoscale_configuration == null ? true : (
      var.autoscale_configuration.min_capacity >= 0 && var.autoscale_configuration.max_capacity >= 2 &&
      var.autoscale_configuration.max_capacity <= 125 && var.autoscale_configuration.min_capacity <= var.autoscale_configuration.max_capacity &&
      floor(var.autoscale_configuration.min_capacity) == var.autoscale_configuration.min_capacity && floor(var.autoscale_configuration.max_capacity) == var.autoscale_configuration.max_capacity
    )
    error_message = "Autoscaling requires integer bounds with 0 <= min_capacity <= max_capacity and 2 <= max_capacity <= 125."
  }
}
variable "zones" {
  description = "Availability zones. Confirm regional support before deployment."
  type        = set(string)
  default     = []
  nullable    = false
}
variable "http2_enabled" {
  description = "Enable HTTP/2 on frontend listeners."
  type        = bool
  default     = true
  nullable    = false
}
variable "identity_ids" {
  description = "User-assigned identity resource IDs, required for Key Vault certificates. Permissions remain caller-managed."
  type        = set(string)
  default     = []
  nullable    = false
}
variable "firewall_policy_id" {
  description = "Existing WAF policy resource ID. Requires WAF_v2."
  type        = string
  default     = null
}
variable "add_public_ip" {
  description = "Create a Standard static public IP and merge its frontend into frontend_ip_configurations."
  type        = bool
  default     = false
  nullable    = false
}
variable "public_ip_name" {
  description = "Managed public IP name override. Defaults to settings.name_prefix followed by pip."
  type        = string
  default     = null
}
variable "public_ip_configuration_name" {
  description = "Managed public frontend name for listener references. Overrides a matching frontend_ip_configurations key when add_public_ip is true."
  type        = string
  default     = "public"
  nullable    = false
  validation {
    condition     = length(trimspace(var.public_ip_configuration_name)) > 0
    error_message = "public_ip_configuration_name must not be empty."
  }
}
variable "frontend_ip_configurations" {
  description = "Frontend configurations keyed by name. Each references a public IP or specifies a static private IP on subnet_id. May be empty when add_public_ip is true."
  type        = map(object({ public_ip_address_id = optional(string), private_ip_address = optional(string) }))
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for f in values(var.frontend_ip_configurations) : (f.public_ip_address_id != null) != (f.private_ip_address != null)])
    error_message = "Each frontend must specify exactly one public_ip_address_id or private_ip_address."
  }
}
variable "frontend_ports" {
  description = "Frontend TCP ports keyed by name."
  type        = map(number)
  nullable    = false
  validation {
    condition     = length(var.frontend_ports) > 0 && alltrue([for port in values(var.frontend_ports) : port >= 1 && port <= 65535 && floor(port) == port])
    error_message = "Provide at least one integer frontend port from 1 to 65535."
  }
}
variable "backend_address_pools" {
  description = "Backend pools keyed by name. Empty pools can be populated later."
  type        = map(object({ fqdns = optional(set(string), []), ip_addresses = optional(set(string), []) }))
  nullable    = false
  validation {
    condition     = length(var.backend_address_pools) > 0
    error_message = "Provide at least one backend pool."
  }
}
variable "backend_http_settings" {
  description = "Backend HTTP settings keyed by name. Use HTTPS and trusted certificates for encrypted backend traffic."
  type = map(object({
    port                                = number
    protocol                            = optional(string, "Http")
    cookie_based_affinity               = optional(string, "Disabled")
    request_timeout                     = optional(number, 30)
    host_name                           = optional(string)
    pick_host_name_from_backend_address = optional(bool, false)
    path                                = optional(string)
    probe_name                          = optional(string)
    trusted_root_certificate_names      = optional(list(string), [])
    connection_draining                 = optional(object({ enabled = optional(bool, true), drain_timeout_sec = optional(number, 30) }))
  }))
  nullable = false
  validation {
    condition     = length(var.backend_http_settings) > 0 && alltrue([for b in values(var.backend_http_settings) : contains(["Http", "Https"], b.protocol) && contains(["Enabled", "Disabled"], b.cookie_based_affinity) && b.port >= 1 && b.port <= 65535 && floor(b.port) == b.port && !(b.host_name != null && b.pick_host_name_from_backend_address)])
    error_message = "Provide backend settings with Http/Https, Enabled/Disabled affinity, valid integer ports, and at most one hostname source."
  }
}
variable "http_listeners" {
  description = "Listeners keyed by name. HTTPS requires a named Key Vault certificate."
  type = map(object({
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = optional(string, "Http")
    host_name                      = optional(string)
    host_names                     = optional(list(string), [])
    require_sni                    = optional(bool, false)
    ssl_certificate_name           = optional(string)
  }))
  nullable = false
  validation {
    condition     = length(var.http_listeners) > 0 && alltrue([for l in values(var.http_listeners) : contains(["Http", "Https"], l.protocol) && (l.protocol == "Https" ? l.ssl_certificate_name != null : l.ssl_certificate_name == null) && !(l.host_name != null && length(l.host_names) > 0)])
    error_message = "Provide listeners with Http or Https; only HTTPS requires a certificate. Use host_name or host_names, not both."
  }
}
variable "request_routing_rules" {
  description = "Basic or path-based routing rules keyed by name. Priorities must be unique."
  type = map(object({
    priority                   = number
    http_listener_name         = string
    rule_type                  = optional(string, "Basic")
    backend_address_pool_name  = optional(string)
    backend_http_settings_name = optional(string)
    url_path_map_name          = optional(string)
  }))
  nullable = false
  validation {
    condition = length(var.request_routing_rules) > 0 && length(distinct([for r in values(var.request_routing_rules) : r.priority])) == length(var.request_routing_rules) && alltrue([for r in values(var.request_routing_rules) :
      r.priority >= 1 && r.priority <= 20000 && floor(r.priority) == r.priority &&
      (r.rule_type == "Basic" ? (r.backend_address_pool_name != null && r.backend_http_settings_name != null && r.url_path_map_name == null) : (r.rule_type == "PathBasedRouting" && r.url_path_map_name != null && r.backend_address_pool_name == null && r.backend_http_settings_name == null))
    ])
    error_message = "Provide unique integer priorities 1..20000. Basic rules require backend pool/settings only; PathBasedRouting rules require a URL path map only."
  }
}
variable "url_path_maps" {
  description = "Path maps keyed by name. Path rules are ordered lists because matching order matters."
  type = map(object({
    default_backend_address_pool_name  = string
    default_backend_http_settings_name = string
    path_rules                         = list(object({ name = string, paths = list(string), backend_address_pool_name = string, backend_http_settings_name = string }))
  }))
  default  = {}
  nullable = false
}
variable "probes" {
  description = "Health probes keyed by name. Specify host or pick_host_name_from_backend_http_settings."
  type = map(object({
    protocol                                  = optional(string, "Http")
    path                                      = optional(string, "/")
    host                                      = optional(string)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    interval                                  = optional(number, 30)
    timeout                                   = optional(number, 30)
    unhealthy_threshold                       = optional(number, 3)
    port                                      = optional(number)
    match                                     = optional(object({ status_code = optional(list(string), ["200-399"]), body = optional(string) }))
  }))
  default  = {}
  nullable = false
}
variable "ssl_certificates" {
  description = "Key Vault certificate secret IDs keyed by certificate name. Prefer versionless secret IDs for rotation."
  type        = map(object({ key_vault_secret_id = string }))
  default     = {}
  nullable    = false
}
variable "trusted_root_certificates" {
  description = "Base64-encoded backend root certificates keyed by name."
  type        = map(string)
  default     = {}
  nullable    = false
}
variable "ssl_policy_name" {
  description = "Predefined frontend TLS policy."
  type        = string
  default     = "AppGwSslPolicy20220101S"
  nullable    = false
}
