locals {
  name = coalesce(var.extension.name, "${var.settings.name_prefix}ext")
}

resource "azurerm_kubernetes_cluster_extension" "extension" {
  name                             = local.name
  cluster_id                       = var.cluster_id
  extension_type                   = var.extension.extension_type
  release_train                    = var.extension.version == null ? var.extension.release_train : null
  release_namespace                = var.extension.release_namespace
  version                          = var.extension.version
  configuration_settings           = var.extension.configuration_settings
  configuration_protected_settings = var.configuration_protected_settings
}


