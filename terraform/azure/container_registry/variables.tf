variable "settings" {
  description = "Shared solution settings used for the registry name and Azure region."
  type = object({
    name_prefix = string
    region_long = string
  })
  nullable = false
}

variable "name" {
  description = "Optional globally unique registry name. Defaults to the lowercase alphanumeric settings.name_prefix followed by acr."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the existing resource group."
  type        = string
  nullable    = false
}

variable "sku" {
  description = "The registry pricing tier: Basic, Standard, or Premium."
  type        = string
  default     = "Basic"
  nullable    = false

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable the registry admin account. Prefer Microsoft Entra authentication and role assignments."
  type        = bool
  default     = false
  nullable    = false
}

variable "anonymous_pull_enabled" {
  description = "Allow unauthenticated image pulls. Requires Standard or Premium."
  type        = bool
  default     = false
  nullable    = false
}

variable "public_network_access_enabled" {
  description = "Allow registry access through the public endpoint. Private endpoints are managed separately."
  type        = bool
  default     = true
  nullable    = false
}

variable "network_rule_bypass_option" {
  description = "Allow trusted Azure services to bypass network rules: AzureServices or None."
  type        = string
  default     = "AzureServices"
  nullable    = false

  validation {
    condition     = contains(["AzureServices", "None"], var.network_rule_bypass_option)
    error_message = "network_rule_bypass_option must be AzureServices or None."
  }
}

variable "network_rule_set" {
  description = "Optional Premium network rules with an Allow or Deny default and IPv4 CIDR allow rules."
  type = object({
    default_action = optional(string, "Deny")
    ip_ranges      = optional(set(string), [])
  })
  default = null

  validation {
    condition     = var.network_rule_set == null ? true : contains(["Allow", "Deny"], var.network_rule_set.default_action)
    error_message = "network_rule_set.default_action must be Allow or Deny."
  }

  validation {
    condition     = var.network_rule_set == null ? true : alltrue([for ip_range in var.network_rule_set.ip_ranges : can(cidrnetmask(ip_range))])
    error_message = "network_rule_set.ip_ranges must contain valid IPv4 CIDR ranges."
  }
}

variable "data_endpoint_enabled" {
  description = "Enable dedicated data endpoints. Requires Premium."
  type        = bool
  default     = false
  nullable    = false
}

variable "export_policy_enabled" {
  description = "Allow artifact exports. Disabling exports requires Premium and disabled public network access."
  type        = bool
  default     = true
  nullable    = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy in a supported region. Requires Premium."
  type        = bool
  default     = false
  nullable    = false
}

variable "identity" {
  description = "Optional registry identity. UserAssigned types require identity_ids. This identity does not grant clients access to images."
  type = object({
    type         = string
    identity_ids = optional(set(string), [])
  })
  default = null

  validation {
    condition     = var.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }

  validation {
    condition     = var.identity == null ? true : (contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type) ? length(var.identity.identity_ids) > 0 : length(var.identity.identity_ids) == 0)
    error_message = "identity_ids must be nonempty for UserAssigned identities and empty for SystemAssigned identities."
  }
}

variable "georeplications" {
  description = "Optional Premium replicas in distinct Azure regions other than settings.region_long."
  type = list(object({
    location                        = string
    zone_redundancy_enabled         = optional(bool, false)
    global_endpoint_routing_enabled = optional(bool, true)
    tags                            = optional(map(string), {})
  }))
  default  = []
  nullable = false

  validation {
    condition     = length(distinct([for replica in var.georeplications : lower(replica.location)])) == length(var.georeplications)
    error_message = "Georeplication locations must be unique."
  }
}

variable "tags" {
  description = "Tags to assign to the registry. Replica tags are configured separately."
  type        = map(string)
  default     = {}
  nullable    = false
}
