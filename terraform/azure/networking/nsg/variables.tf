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

  validation {
    condition = alltrue([
      for rule in var.rules : try(rule.priority >= 100 && rule.priority <= 4096 && floor(rule.priority) == rule.priority, false)
    ])
    error_message = "Rule priorities must be integers from 100 to 4096."
  }

  validation {
    condition = length(distinct([
      for rule in var.rules : jsonencode([rule.direction, rule.priority])
    ])) == length(var.rules)
    error_message = "Rule priorities must be unique within each direction."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : try(contains(["Inbound", "Outbound"], rule.direction), false)
    ])
    error_message = "Rule direction must be Inbound or Outbound."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : try(contains(["Allow", "Deny"], rule.access), false)
    ])
    error_message = "Rule access must be Allow or Deny."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : try(contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol), false)
    ])
    error_message = "Rule protocol must be Tcp, Udp, Icmp, Esp, Ah, or *."
  }

  validation {
    condition = alltrue([
      for rule in var.rules :
      length([for selected in [rule.source_port_range != null, rule.source_port_ranges != null] : selected if selected]) <= 1 &&
      length([for selected in [rule.destination_port_range != null, rule.destination_port_ranges != null] : selected if selected]) == 1
    ])
    error_message = "Rules must specify exactly one destination port selector and at most one source port selector."
  }

  validation {
    condition = alltrue([
      for rule in var.rules :
      length([for selected in [rule.source_address_prefix != null, rule.source_address_prefixes != null, rule.source_application_security_group_ids != null] : selected if selected]) == 1 &&
      length([for selected in [rule.destination_address_prefix != null, rule.destination_address_prefixes != null, rule.destination_application_security_group_ids != null] : selected if selected]) <= 1
    ])
    error_message = "Rules must specify exactly one source address selector and at most one destination address selector."
  }

  validation {
    condition = alltrue(flatten([
      for rule in var.rules : [
        for values in [rule.source_port_ranges, rule.destination_port_ranges, rule.source_address_prefixes, rule.destination_address_prefixes, rule.source_application_security_group_ids, rule.destination_application_security_group_ids] :
        values == null ? true : length(values) > 0
      ]
    ]))
    error_message = "Rule port, address, and application security group sets must not be empty when supplied."
  }
}

variable "subnet_ids" {
  description = "Subnets to associate with this NSG, keyed by subnet name."
  type        = map(string)
  default     = {}
  nullable    = false
}
