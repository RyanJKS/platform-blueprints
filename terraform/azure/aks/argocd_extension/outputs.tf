output "id" {
  description = "The Argo CD extension resource ID."
  value       = azurerm_kubernetes_cluster_extension.argocd.id
}
