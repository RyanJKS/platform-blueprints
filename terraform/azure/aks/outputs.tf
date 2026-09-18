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

output "argocd_extension_id" {
  description = "The Argo CD extension resource ID, or null when disabled."
  value       = try(azurerm_kubernetes_cluster_extension.argocd[0].id, null)
}

output "web_app_routing_identity" {
  description = "The application routing identity for caller-managed DNS role assignments, or null when disabled."
  value       = try(azurerm_kubernetes_cluster.this.web_app_routing[0].web_app_routing_identity, null)
}

output "kube_config_raw" {
  description = "The cluster kubeconfig. Protect state and prefer Entra authentication for clients."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "The administrator kubeconfig, when Entra integration and local accounts are enabled."
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
}
