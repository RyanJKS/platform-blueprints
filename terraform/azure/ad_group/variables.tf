variable "display_name" {
  description = "The display name of the security group."
  type        = string
  nullable    = false
}

variable "description" {
  description = "The description of the security group."
  type        = string
  default     = null
}

variable "owners" {
  description = "Object IDs of group owners."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "members" {
  description = "Object IDs of direct group members."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "prevent_duplicate_names" {
  description = "Whether to reject an existing group with the same display name."
  type        = bool
  default     = true
  nullable    = false
}
