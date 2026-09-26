mock_provider "azuread" {}

variables {
  display_name = "aks-admins"
}

run "security_group" {
  command = plan
  assert {
    condition     = azuread_group.this.security_enabled && !azuread_group.this.mail_enabled && azuread_group.this.prevent_duplicate_names
    error_message = "Create a security-only group and prevent duplicate names by default."
  }
}
