variable "assignments" {
  description = "Role assignments keyed by stable, caller-chosen names. Keys must be known at plan time; values may use dependency outputs."
  type = map(object({
    scope                            = string
    principal_id                     = string
    type                             = string
    role_definition_name             = optional(string)
    role_definition_id               = optional(string)
    name                             = optional(string)
    description                      = optional(string)
    condition                        = optional(string)
    skip_service_principal_aad_check = optional(bool, false)
  }))
  nullable = false

  validation {
    condition = alltrue([
      for assignment in var.assignments : contains(["User", "Group", "ServicePrincipal"], assignment.type)
    ])
    error_message = "type must be User, Group, or ServicePrincipal."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments : assignment.role_definition_name == null ? true : length(trimspace(assignment.role_definition_name)) > 0
    ])
    error_message = "role_definition_name must not be empty."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments : assignment.condition == null ? true : length(trimspace(assignment.condition)) > 0
    ])
    error_message = "condition must not be empty."
  }
}
