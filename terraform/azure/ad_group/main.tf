resource "azuread_group" "this" {
  for_each = var.groups

  display_name            = each.key
  description             = each.value.description
  security_enabled        = true
  mail_enabled            = false
  owners                  = each.value.owners
  members                 = each.value.members
  prevent_duplicate_names = each.value.prevent_duplicate_names
}
