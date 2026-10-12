resource "azuread_application" "this" {
  display_name = var.name
  owners       = var.owners

  dynamic "web" {
    for_each = length(var.redirect_uris) > 0 ? [var.redirect_uris] : []

    content {
      redirect_uris = web.value
    }
  }

  lifecycle {
    precondition {
      condition     = !var.create_secret || var.key_vault_id != null
      error_message = "key_vault_id is required when create_secret is true."
    }

    precondition {
      condition     = !var.create_secret || (can(regex("^[0-9A-Za-z-]+$", var.name)) && length(var.name) <= 113)
      error_message = "When create_secret is true, name must contain only letters, numbers, and hyphens and be at most 113 characters so both Key Vault secret names are valid."
    }
  }
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
  owners    = var.owners
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each = var.federated_identity_credentials

  application_id = azuread_application.this.id
  display_name   = each.key
  issuer         = each.value.issuer
  subject        = each.value.subject
  audiences      = each.value.audiences
  description    = each.value.description
}

resource "azuread_service_principal_password" "this" {
  count = var.create_secret ? 1 : 0

  service_principal_id = azuread_service_principal.this.id
  display_name         = "${var.name}-client-secret"
}

resource "azurerm_key_vault_secret" "client_id" {
  count = var.create_secret ? 1 : 0

  name         = "${var.name}-client-id"
  value        = azuread_service_principal.this.client_id
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "client_secret" {
  count = var.create_secret ? 1 : 0

  name         = "${var.name}-client-secret"
  value        = azuread_service_principal_password.this[0].value
  key_vault_id = var.key_vault_id
}
