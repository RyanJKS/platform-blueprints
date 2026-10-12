variable "name" {
  description = "The display name of the application and service principal. Used as the prefix for Key Vault secret names."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must contain at least one non-whitespace character."
  }
}

variable "owners" {
  description = "The object IDs of the owners of the application and service principal."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "redirect_uris" {
  description = "Web redirect URIs for application sign-in callbacks, such as an Argo CD OIDC callback URL."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for uri in var.redirect_uris : try(length(trimspace(uri)) > 0, false)])
    error_message = "Each redirect URI must be a nonempty string."
  }
}

variable "federated_identity_credentials" {
  description = "Optional application federated identity credentials keyed by credential name. Each credential trusts an issuer and subject for the specified audiences."
  type = map(object({
    issuer      = string
    subject     = string
    audiences   = optional(list(string), ["api://AzureADTokenExchange"])
    description = optional(string)
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
      length(credential.audiences) == 1 &&
      alltrue([for audience in credential.audiences : try(length(trimspace(audience)) > 0, false)])
    ])
    error_message = "Each federated credential must contain exactly one nonempty audience."
  }
}

variable "create_secret" {
  description = "Whether to create a service principal password and store its value and client ID in Key Vault."
  type        = bool
  default     = false
  nullable    = false
}

variable "key_vault_id" {
  description = "The resource ID of an existing Azure Key Vault. Required when create_secret is true."
  type        = string
  default     = null

  validation {
    condition     = var.key_vault_id == null ? true : length(trimspace(var.key_vault_id)) > 0
    error_message = "key_vault_id must be null or a nonempty Key Vault resource ID."
  }
}
