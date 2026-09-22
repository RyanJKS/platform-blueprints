variable "solution_name" {
  description = "The solution name shared by consuming modules."
  type        = string
  nullable    = false
}

variable "env" {
  description = "The environment name, such as dev, staging, or prod."
  type        = string
  nullable    = false
}

variable "region_short" {
  description = "The region abbreviation used in resource names, such as uks."
  type        = string
  nullable    = false
}

variable "region_long" {
  description = "The Azure location identifier, such as uksouth."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Shared tags. The module passes these through without adding or overriding tags."
  type        = map(string)
  default     = {}
  nullable    = false
}
