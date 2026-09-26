variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over these defaults."
  type = object({
    name_prefix = string
    region_long = string
    tenant_id   = string
  })
  nullable = false
}

variable "name" {
  description = "Optional resource name override. Defaults to settings.name_prefix followed by akv."
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

variable "tenant_id" {
  description = "Optional tenant ID override. Defaults to settings.tenant_id."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "The Key Vault SKU."
  type        = string
  default     = "standard"
  nullable    = false

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The SKU must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "The retention period for deleted vaults and objects."
  type        = number
  default     = 90
  nullable    = false

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90 && floor(var.soft_delete_retention_days) == var.soft_delete_retention_days
    error_message = "The retention period must be an integer between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Whether to enable irreversible purge protection."
  type        = bool
  default     = true
  nullable    = false
}

variable "public_network_access_enabled" {
  description = "Whether to allow access through the public endpoint."
  type        = bool
  default     = false
  nullable    = false
}
