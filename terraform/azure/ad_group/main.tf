resource "azuread_group" "this" {
  display_name            = var.display_name
  description             = var.description
  security_enabled        = true
  mail_enabled            = false
  owners                  = var.owners
  members                 = var.members
  prevent_duplicate_names = var.prevent_duplicate_names
}
