# LocalDNS API reference:
# https://learn.microsoft.com/en-us/azure/templates/microsoft.containerservice/2025-10-01/managedclusters/agentpools?pivots=deployment-language-terraform
resource "azapi_update_resource" "localdns" {
  for_each = var.local_dns_profiles

  type        = "Microsoft.ContainerService/managedClusters/agentPools@2025-10-01"
  resource_id = try(azurerm_kubernetes_cluster_node_pool.this[each.key].id, null)

  body = {
    properties = {
      localDNSProfile = each.value
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(var.additional_node_pools), each.key)
      error_message = "Each local_dns_profiles key must name a pool in additional_node_pools."
    }
  }

  # Serialize pool updates after the optional cluster-wide kube-proxy update.
  depends_on = [azapi_update_resource.kube_proxy_disabled]
}
