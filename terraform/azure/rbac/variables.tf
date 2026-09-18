variable "scope" {
  description = "The Azure resource, resource group, subscription, or management group resource ID at which to assign the role."
  type        = string
  nullable    = false
}

variable "principal_id" {
  description = "The Microsoft Entra object ID of the principal. Use a managed identity principal_id, not its client_id or resource ID."
  type        = string
  nullable    = false
}

variable "type" {
  description = "The principal type: User, Group, or ServicePrincipal. Managed identities use ServicePrincipal."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["User", "Group", "ServicePrincipal"], var.type)
    error_message = "type must be User, Group, or ServicePrincipal."
  }
}

variable "role_definition_name" {
  description = "The built-in Azure role name, such as Reader. Set this or role_definition_id, but not both."
  type        = string
  default     = null

  validation {
    condition     = var.role_definition_name == null ? true : length(trimspace(var.role_definition_name)) > 0
    error_message = "role_definition_name must not be empty."
  }
}

variable "role_definition_id" {
  description = "The full scoped Azure role definition resource ID, including for custom roles. Mutually exclusive with role_definition_name."
  type        = string
  default     = null
}

variable "name" {
  description = "An optional role assignment UUID. Azure generates one when omitted."
  type        = string
  default     = null
}

variable "description" {
  description = "An optional description of the role assignment."
  type        = string
  default     = null
}

variable "condition" {
  description = "An optional Azure ABAC condition. When set, condition version 2.0 is used."
  type        = string
  default     = null

  validation {
    condition     = var.condition == null ? true : length(trimspace(var.condition)) > 0
    error_message = "condition must not be empty."
  }
}

variable "skip_service_principal_aad_check" {
  description = "Skip the Entra existence check for a newly created service principal or managed identity."
  type        = bool
  default     = false
  nullable    = false
}

