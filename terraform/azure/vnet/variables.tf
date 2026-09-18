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
  type        = map(object({ address_prefixes = list(string) }))
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for subnet in values(var.subnets) : length(subnet.address_prefixes) > 0 && alltrue([for cidr in subnet.address_prefixes : can(cidrhost(cidr, 0))])])
    error_message = "Each subnet must have at least one valid CIDR range."
  }
}
