output "id" {
  description = "The id of the resource."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "The name of the resource."
  value       = azurerm_kubernetes_cluster.this.name
}

output "location" {
  description = "The location of the resource."
  value       = azurerm_kubernetes_cluster.this.location
}

output "tags" {
  description = "The tags of the resource."
  value       = azurerm_kubernetes_cluster.this.tags
}

output "node_resource_group" {
  description = "The node resource group of the resource."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "node_resource_group_id" {
  description = "The managed resource group id created by azure"
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

output "oidc_issuer_url" {
  description = "The oidc issuer url of the resource."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "identity" {
  description = "The cluster control-plane identity."
  value       = azurerm_kubernetes_cluster.this.identity
}

output "kubelet_identity" {
  description = "The identity used by kubelets."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "web_app_routing_identity" {
  description = "The application routing identity for caller-managed DNS role assignments, or null when disabled."
  value       = try(azurerm_kubernetes_cluster.this.web_app_routing[0].web_app_routing_identity, null)
}

output "host" {
  description = "The Kubernetes API endpoint from the cluster kubeconfig, or null when unavailable."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].host, null)
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The base64-encoded Kubernetes cluster CA certificate, or null when unavailable."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate, null)
  sensitive   = true
}

output "fqdn" {
  description = "The cluster API server FQDN."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  description = "The private cluster API server FQDN, when configured."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "minimum_node_count" {
  description = "The configured node count, or minimum node count when autoscaling."
  value       = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.min_count : var.default_node_pool.node_count
}

output "ingress_application_gateway_identity" {
  description = "The Application Gateway ingress addon identity for caller-managed role assignments, or null when disabled."
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity, null)
}

output "oms_agent_identity" {
  description = "The Container Insights addon identity, or null when disabled."
  value       = try(azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity, null)
}

output "additional_node_pool_ids" {
  description = "Additional node pool resource IDs, keyed by pool name."
  value       = { for name, pool in azurerm_kubernetes_cluster_node_pool.this : name => pool.id }
}

output "container_insights_data_collection_rule_id" {
  description = "The managed Container Insights DCR ID, or null when disabled."
  value       = try(azurerm_monitor_data_collection_rule.container_insights[0].id, null)
}
