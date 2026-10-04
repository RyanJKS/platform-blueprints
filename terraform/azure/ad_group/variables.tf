variable "groups" {
  description = "Security groups keyed by display name, with optional descriptions, owners, members, and duplicate-name prevention."
  type = map(object({
    description             = optional(string)
    owners                  = optional(set(string), [])
    members                 = optional(set(string), [])
    prevent_duplicate_names = optional(bool, true)
  }))
  nullable = false

  validation {
    condition     = alltrue([for name in keys(var.groups) : length(trimspace(name)) > 0])
    error_message = "Each groups key must be a nonempty group display name."
  }
}
