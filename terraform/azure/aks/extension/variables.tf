variable "settings" {
  description = "Shared solution settings used to generate the default name."
  type = object({
    name_prefix = string
  })
  nullable = false
}

variable "cluster_id" {
  description = "The resource ID of the AKS cluster."
  type        = string
  nullable    = false
}

variable "extension" {
  description = "The extension type and its deployment settings. Use one module instance per extension."
  type = object({
    extension_type         = string
    name                   = optional(string)
    release_train          = optional(string, "Stable")
    release_namespace      = optional(string)
    version                = optional(string)
    configuration_settings = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = try(trimspace(var.extension.extension_type) != "", false)
    error_message = "extension.extension_type must be a non-empty string."
  }

  validation {
    condition     = var.extension.release_namespace == null ? true : can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", var.extension.release_namespace))
    error_message = "extension.release_namespace must be a valid Kubernetes DNS label of at most 63 characters."
  }
}

variable "configuration_protected_settings" {
  description = "Sensitive extension settings. These values are still stored in Terraform state."
  type        = map(string)
  default     = {}
  nullable    = false
  sensitive   = true
}
