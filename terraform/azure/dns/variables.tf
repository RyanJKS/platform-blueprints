variable "name" {
  description = "The DNS zone name, such as example.com."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the existing resource group."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to assign to the DNS zone."
  type        = map(string)
  default     = {}
  nullable    = false
}
