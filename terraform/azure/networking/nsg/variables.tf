variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over these defaults."
  type = object({
    name_prefix = string
    region_long = string
  })
  nullable = false
}

variable "name" {
  description = "Optional resource name override. Defaults to settings.name_prefix followed by nsg."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the existing resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Optional Azure region override. Defaults to settings.region_long."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to assign to the resource."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "rules" {
  description = "NSG rules keyed by rule name."

  type = map(object({
    description = optional(string)
    priority    = number
    direction   = string
    access      = string
    protocol    = string

    source_port_range       = optional(string)
    source_port_ranges      = optional(set(string))
    destination_port_range  = optional(string)
    destination_port_ranges = optional(set(string))

    source_address_prefix                 = optional(string)
    source_address_prefixes               = optional(set(string))
    source_application_security_group_ids = optional(set(string))

    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
  }))

  default  = {}
  nullable = false
}

variable "subnet_ids" {
  description = "Subnets to associate with this NSG, keyed by subnet name."
  type        = map(string)
  default     = {}
  nullable    = false
}
