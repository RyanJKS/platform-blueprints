locals {
  name     = coalesce(var.name, "${var.settings.name_prefix}id")
  location = coalesce(var.location, var.settings.region_long)
}

resource "azurerm_user_assigned_identity" "this" {
  name                = local.name
  resource_group_name = var.resource_group_name
  location            = local.location
  tags                = var.tags
}
