variable "cluster_id" {
  description = "The resource ID of the managed-identity AKS cluster."
  type        = string
  nullable    = false
}

variable "minimum_node_count" {
  description = "The cluster node_count, or min_count when autoscaling. Used to validate Argo CD HA capacity."
  type        = number
  nullable    = false
  validation {
    condition     = var.minimum_node_count >= 1 && floor(var.minimum_node_count) == var.minimum_node_count
    error_message = "minimum_node_count must be a positive integer."
  }
}

variable "argocd" {
  description = "Argo CD extension settings. Null disables the extension; an empty object enables the defaults."
  type = object({
    name                   = optional(string, "argocd-ext")
    release_train          = optional(string, "preview")
    version                = optional(string)
    namespace              = optional(string, "argocd")
    namespace_install      = optional(bool, false)
    high_availability      = optional(bool, false)
    configuration_settings = optional(map(string), {})
  })
  default  = {}
  nullable = false

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", var.argocd.namespace))
    error_message = "The Argo CD namespace must be a valid Kubernetes DNS label of at most 63 characters."
  }
}
