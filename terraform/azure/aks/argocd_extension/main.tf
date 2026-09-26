locals {
  name = coalesce(var.argocd.name, "${var.settings.name_prefix}argocd")
}

resource "azurerm_kubernetes_cluster_extension" "argocd" {
  name              = local.name
  cluster_id        = var.cluster_id
  extension_type    = "microsoft.argocd"
  release_train     = var.argocd.release_train
  release_namespace = var.argocd.namespace
  version           = var.argocd.version

  configuration_settings = merge(var.argocd.configuration_settings, {
    deployWithHighAvailability = tostring(var.argocd.high_availability)
    "redis-ha.enabled"         = tostring(var.argocd.high_availability)
    namespaceInstall           = tostring(var.argocd.namespace_install)
  })

  lifecycle {
    precondition {
      condition     = !var.argocd.high_availability || var.minimum_node_count >= 4
      error_message = "Argo CD HA requires at least four nodes: set minimum_node_count to the cluster node_count or autoscaling min_count (4 or more)."
    }
  }
}
