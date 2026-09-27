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

output "web_app_routing_identity" {
  description = "The application routing identity for caller-managed DNS role assignments, or null when disabled."
  value       = try(azurerm_kubernetes_cluster.this.web_app_routing[0].web_app_routing_identity, null)
}

output "kube_config_raw" {
  description = "The cluster kubeconfig. Protect state and prefer Entra authentication for clients."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "The raw cluster kubeconfig YAML, aliased from kube_config_raw for dependency consumers."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_config_credentials" {
  description = "The structured cluster connection settings, or null when unavailable. Certificate fields are base64 encoded."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0], null)
  sensitive   = true
}

output "host" {
  description = "The Kubernetes API endpoint from the cluster kubeconfig, or null when unavailable."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].host, null)
  sensitive   = true
}

output "client_certificate" {
  description = "The base64-encoded client certificate, or null when unavailable. Entra authentication may not provide this credential."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate, null)
  sensitive   = true
}

output "client_key" {
  description = "The base64-encoded client private key, or null when unavailable. Entra authentication may not provide this credential."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].client_key, null)
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The base64-encoded Kubernetes cluster CA certificate, or null when unavailable."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate, null)
  sensitive   = true
}

output "username" {
  description = "The kubeconfig username, or null when unavailable. This may be empty for certificate or Entra authentication."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].username, null)
  sensitive   = true
}

output "password" {
  description = "The kubeconfig password, or null when unavailable. This may be empty for certificate or Entra authentication."
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].password, null)
  sensitive   = true
}

output "kube_admin_config_credentials" {
  description = "The structured administrator connection settings, or null when unavailable. Requires Entra integration with local accounts enabled."
  value       = try(azurerm_kubernetes_cluster.this.kube_admin_config[0], null)
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

output "kube_admin_config_raw" {
  description = "The administrator kubeconfig, when Entra integration and local accounts are enabled."
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
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
