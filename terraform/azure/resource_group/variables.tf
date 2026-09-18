variable "name" {
  description = "The name of the Azure resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region in which to create the resource group, such as uksouth."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to assign to the resource group."
  type        = map(string)
  default     = {}
  nullable    = false
}
