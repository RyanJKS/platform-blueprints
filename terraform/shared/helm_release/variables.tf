variable "release" {
  description = "Helm release and lifecycle settings. Use one module instance per release."
  type = object({
    name              = string
    chart             = string
    repository        = optional(string)
    version           = optional(string)
    namespace         = optional(string, "default")
    create_namespace  = optional(bool, false)
    description       = optional(string)
    atomic            = optional(bool, false)
    cleanup_on_fail   = optional(bool, false)
    dependency_update = optional(bool, false)
    wait              = optional(bool, true)
    wait_for_jobs     = optional(bool, false)
    timeout           = optional(number, 300)
    max_history       = optional(number, 0)
    skip_crds         = optional(bool, false)
  })
  nullable = false

  validation {
    condition     = try(length(var.release.name) <= 53 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.release.name)), false)
    error_message = "release.name must be a lowercase DNS label of at most 53 characters."
  }

  validation {
    condition     = try(trimspace(var.release.chart) != "", false)
    error_message = "release.chart must be a non-empty chart name, path, or URL."
  }

  validation {
    condition     = length(var.release.namespace) <= 63 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.release.namespace))
    error_message = "release.namespace must be a lowercase DNS label of at most 63 characters."
  }

  validation {
    condition     = var.release.timeout > 0 && floor(var.release.timeout) == var.release.timeout
    error_message = "release.timeout must be a positive integer in seconds."
  }

  validation {
    condition     = var.release.max_history >= 0 && floor(var.release.max_history) == var.release.max_history
    error_message = "release.max_history must be a non-negative integer; zero keeps unlimited history."
  }
}

variable "values" {
  description = "YAML values documents, merged in order. Use file() or yamlencode() in the caller. Values remain in Terraform state."
  type        = list(string)
  default     = []
  nullable    = false
  sensitive   = true
}

variable "set" {
  description = "Individual chart values that override YAML values. Type is auto or string."
  type = list(object({
    name  = string
    value = string
    type  = optional(string, "auto")
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for setting in var.set : contains(["auto", "string"], setting.type)])
    error_message = "Each set entry must use type auto or string."
  }
}

variable "set_sensitive" {
  description = "Sensitive individual chart values. Terraform still stores these values in state."
  type = list(object({
    name  = string
    value = string
    type  = optional(string, "auto")
  }))
  default   = []
  nullable  = false
  sensitive = true

  validation {
    condition     = alltrue([for setting in var.set_sensitive : contains(["auto", "string"], setting.type)])
    error_message = "Each set_sensitive entry must use type auto or string."
  }
}
