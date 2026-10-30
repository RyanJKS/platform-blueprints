locals {
  name               = coalesce(var.name, "${var.settings.name_prefix}id")
  location           = coalesce(var.location, var.settings.region_long)
  secret_name_prefix = "${coalesce(var.secret_name_prefix, local.name)}-"
}

resource "azurerm_user_assigned_identity" "this" {
  name                = local.name
  resource_group_name = var.resource_group_name
  location            = local.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = var.federated_identity_credentials

  name                      = each.key
  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  issuer                    = each.value.issuer
  subject                   = each.value.subject
  audience                  = each.value.audience
}

resource "azurerm_key_vault_secret" "client_id" {
  name         = "${local.secret_name_prefix}client-id"
  value        = azurerm_user_assigned_identity.this.client_id
  key_vault_id = var.key_vault_id
}
