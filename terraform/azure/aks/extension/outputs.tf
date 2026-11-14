output "id" {
  description = "The extension resource ID."
  value       = azurerm_kubernetes_cluster_extension.extension.id
}

output "aks_assigned_identity" {
  description = "The AKS-assigned extension identity (principal_id, tenant_id, and type), or null when Azure does not assign one."
  value       = try(azurerm_kubernetes_cluster_extension.extension.aks_assigned_identity[0], null)
}
