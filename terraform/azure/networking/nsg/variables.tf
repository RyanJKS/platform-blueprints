variable "name" {
  description = "The resource name."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the existing resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region in which to create the resource."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to assign to the resource."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "rules" {
  description = "Custom security rules keyed by Azure rule name. An empty map creates no custom rules."
  type = map(object({
    description                                = optional(string)
    priority                                   = number
    direction                                  = string
    access                                     = string
    protocol                                   = string
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(set(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(set(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(set(string))
    source_application_security_group_ids      = optional(set(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for rule in values(var.rules) : rule.priority >= 100 && rule.priority <= 4096 && floor(rule.priority) == rule.priority])
    error_message = "Rule priorities must be integers between 100 and 4096."
  }
  validation {
    condition     = length(distinct([for rule in values(var.rules) : "${rule.direction}:${rule.priority}"])) == length(var.rules)
    error_message = "Rule priorities must be unique within each direction."
  }
  validation {
    condition     = alltrue([for rule in values(var.rules) : contains(["Inbound", "Outbound"], rule.direction) && contains(["Allow", "Deny"], rule.access) && contains(["*", "Tcp", "Udp", "Icmp", "Esp", "Ah"], rule.protocol)])
    error_message = "Rules require direction Inbound/Outbound, access Allow/Deny, and protocol *, Tcp, Udp, Icmp, Esp, or Ah."
  }
  validation {
    condition     = alltrue([for rule in values(var.rules) : !(rule.source_port_range != null && rule.source_port_ranges != null) && ((rule.destination_port_range != null) != (rule.destination_port_ranges != null))])
    error_message = "Set at most one source port selector and exactly one destination port selector (range or ranges)."
  }
  validation {
    condition     = alltrue([for rule in values(var.rules) : length([for present in [rule.source_address_prefix != null, rule.source_address_prefixes != null, rule.source_application_security_group_ids != null] : present if present]) == 1 && length([for present in [rule.destination_address_prefix != null, rule.destination_address_prefixes != null, rule.destination_application_security_group_ids != null] : present if present]) <= 1])
    error_message = "Set exactly one source address selector and at most one destination address selector (prefix, prefixes, or application security group IDs)."
  }
  validation {
    condition     = alltrue(flatten([for rule in values(var.rules) : [for entries in [rule.source_port_ranges, rule.destination_port_ranges, rule.source_address_prefixes, rule.destination_address_prefixes, rule.source_application_security_group_ids, rule.destination_application_security_group_ids] : entries == null ? true : length(entries) > 0]]))
    error_message = "Port, address, and application security group sets must not be empty when supplied."
  }
}
