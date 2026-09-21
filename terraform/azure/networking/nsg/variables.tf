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
