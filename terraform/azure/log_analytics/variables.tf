variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over defaults."
  type = object({
    name_prefix = string
    region_long = string
  })
  nullable = false
}

variable "name" {
  description = "Optional workspace name override. Defaults to settings.name_prefix followed by law."
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

variable "sku" {
  description = "The workspace pricing tier. Legacy tiers may be unavailable for new workspaces."
  type        = string
  default     = "PerGB2018"
  nullable    = false

  validation {
    condition     = contains(["PerGB2018", "PerNode", "Premium", "Standalone", "Standard", "CapacityReservation", "LACluster", "Unlimited"], var.sku)
    error_message = "sku must be one of: PerGB2018, PerNode, Premium, Standalone, Standard, CapacityReservation, LACluster, Unlimited."
  }
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Daily capacity reservation in GB. Required only when sku is CapacityReservation."
  type        = number
  default     = null

  validation {
    condition = var.reservation_capacity_in_gb_per_day == null ? true : contains([
      50, 100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000, 50000
    ], var.reservation_capacity_in_gb_per_day)
    error_message = "reservation_capacity_in_gb_per_day must be null or one of: 50, 100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000, 50000."
  }
}

variable "retention_in_days" {
  description = "The workspace data retention period, from 30 to 730 days. Individual table settings can override this default."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730 && floor(var.retention_in_days) == var.retention_in_days
    error_message = "retention_in_days must be a whole number between 30 and 730."
  }
}

variable "daily_quota_gb" {
  description = "The daily ingestion cap in GB. Set -1 for unlimited ingestion."
  type        = number
  default     = -1
  nullable    = false

  validation {
    condition     = var.daily_quota_gb == -1 || var.daily_quota_gb > 0
    error_message = "daily_quota_gb must be -1 for unlimited ingestion or a positive number."
  }
}

variable "local_authentication_enabled" {
  description = "Allow shared-key authentication in addition to Microsoft Entra authentication. Disabled by default."
  type        = bool
  default     = false
  nullable    = false
}

variable "allow_resource_only_permissions" {
  description = "Allow users to query logs for resources they can access without a workspace role assignment."
  type        = bool
  default     = true
  nullable    = false
}

variable "internet_ingestion_access_type" {
  description = "Public ingestion access: Enabled, Disabled, or SecuredByPerimeter. Private connectivity or a perimeter must be provisioned separately."
  type        = string
  default     = "Enabled"
  nullable    = false

  validation {
    condition     = contains(["Enabled", "Disabled", "SecuredByPerimeter"], var.internet_ingestion_access_type)
    error_message = "internet_ingestion_access_type must be one of: Enabled, Disabled, SecuredByPerimeter."
  }
}

variable "internet_query_access_type" {
  description = "Public query access: Enabled, Disabled, or SecuredByPerimeter. Private connectivity or a perimeter must be provisioned separately."
  type        = string
  default     = "Enabled"
  nullable    = false

  validation {
    condition     = contains(["Enabled", "Disabled", "SecuredByPerimeter"], var.internet_query_access_type)
    error_message = "internet_query_access_type must be one of: Enabled, Disabled, SecuredByPerimeter."
  }
}

variable "tags" {
  description = "Tags to assign to the workspace."
  type        = map(string)
  default     = {}
  nullable    = false
}
