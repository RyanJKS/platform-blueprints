variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over these defaults."
  type = object({
    name_prefix = string
    region_long = string
  })
  nullable = false
}

variable "federated_identity_credentials" {
  description = "Optional federated identity credentials keyed by credential name. Each credential trusts an issuer and subject for the specified audience."
  type = map(object({
    issuer   = string
    subject  = string
    audience = optional(list(string), ["api://AzureADTokenExchange"])
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for name, credential in var.federated_identity_credentials :
      length(trimspace(name)) > 0 &&
      try(length(trimspace(credential.issuer)) > 0, false) &&
      try(length(trimspace(credential.subject)) > 0, false)
    ])
    error_message = "Each federated credential must have a nonempty name, issuer, and subject."
  }

  validation {
    condition = alltrue([
      for credential in var.federated_identity_credentials :
      length(credential.audience) == 1 &&
      alltrue([for audience in credential.audience : try(length(trimspace(audience)) > 0, false)])
    ])
    error_message = "Each federated credential audience must contain exactly one nonempty string."
  }
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
