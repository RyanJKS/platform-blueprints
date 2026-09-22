variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over these defaults."
  type = object({
    name_prefix = string
    region_long = string
  })
  nullable = false
}

variable "name" {
  description = "Optional resource name override. Defaults to settings.name_prefix followed by id."
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
