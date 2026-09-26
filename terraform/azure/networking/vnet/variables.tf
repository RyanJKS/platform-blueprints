variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over these defaults."
  type = object({
    name_prefix = string
    region_long = string
  })
  nullable = false
}

variable "name" {
  description = "Optional resource name override. Defaults to settings.name_prefix followed by vnet."
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

variable "address_space" {
  description = "The address ranges for the virtual network."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Provide at least one valid CIDR range."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers. An empty list uses Azure DNS."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "subnets" {
  description = "Subnets keyed by subnet name."

  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(set(string), [])
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)

    delegation = optional(object({
      name = string

      service_delegation = object({
        name    = string
        actions = optional(set(string), [])
      })
    }))
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      length(subnet.address_prefixes) > 0 &&
      alltrue([
        for cidr in subnet.address_prefixes :
        can(cidrhost(cidr, 0))
      ])
    ])

    error_message = "Each subnet must have at least one valid CIDR range."
  }
}
