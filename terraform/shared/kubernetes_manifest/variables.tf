variable "manifest" {
  description = "A single Kubernetes manifest as an HCL object or yamldecode() result. Custom resource definitions must already exist before planning."
  type        = any
  nullable    = false

  validation {
    condition = try(
      trimspace(var.manifest.apiVersion) != "" &&
      trimspace(var.manifest.kind) != "" &&
      trimspace(var.manifest.metadata.name) != "",
      false
    )
    error_message = "manifest must contain non-empty apiVersion, kind, and metadata.name fields."
  }
}

variable "computed_fields" {
  description = "Manifest field paths that Kubernetes or controllers may change without causing inconsistent result errors."
  type        = list(string)
  default     = ["metadata.annotations", "metadata.labels"]
  nullable    = false
}

variable "field_manager" {
  description = "Server-side apply field ownership settings. Enable force_conflicts only when intentionally taking ownership from another manager."
  type = object({
    name            = optional(string, "Terraform")
    force_conflicts = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "wait_fields" {
  description = "Optional field paths and regular expressions to wait for after applying, such as status.health.status = Healthy for an Argo CD Application. Null disables waiting."
  type        = map(string)
  default     = null
}

variable "timeouts" {
  description = "Create, update, and delete timeouts as duration strings."
  type = object({
    create = optional(string, "10m")
    update = optional(string, "10m")
    delete = optional(string, "10m")
  })
  default  = {}
  nullable = false
}
