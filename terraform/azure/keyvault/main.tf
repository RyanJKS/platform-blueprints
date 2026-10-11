locals {
  name              = coalesce(var.name, "${var.settings.name_prefix}akv")
  location          = coalesce(var.location, var.settings.region_long)
  tenant_id         = coalesce(var.tenant_id, var.settings.tenant_id)
  creator_object_id = coalesce(var.settings.object_id, data.azurerm_client_config.current.object_id)
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = local.name
  resource_group_name           = var.resource_group_name
  location                      = local.location
  tenant_id                     = local.tenant_id
  sku_name                      = var.sku_name
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

resource "azurerm_role_assignment" "creator" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = local.creator_object_id
}
