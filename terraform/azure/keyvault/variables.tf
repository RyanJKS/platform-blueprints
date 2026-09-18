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

variable "tenant_id" {
  description = "The Microsoft Entra tenant ID."
  type        = string
  nullable    = false
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
