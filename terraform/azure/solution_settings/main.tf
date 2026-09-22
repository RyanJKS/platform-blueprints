locals {
  solution_slug = trim(
    replace(lower(trimspace(var.solution_name)), "/[^a-z0-9]+/", "-"),
    "-"
  )

  name_prefix = "${local.solution_slug}${var.region_short}${var.env}"

  settings = {
    solution_name   = var.solution_name
    solution_slug   = local.solution_slug
    name_prefix     = local.name_prefix
    env             = var.env
    region_short    = var.region_short
    region_long     = var.region_long
    subscription_id = data.azurerm_client_config.current.subscription_id
    tenant_id       = data.azurerm_client_config.current.tenant_id
    client_id       = data.azurerm_client_config.current.client_id
    object_id       = data.azurerm_client_config.current.object_id
  }
}

data "azurerm_client_config" "current" {}
