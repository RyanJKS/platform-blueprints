output "id" {
  description = "The workspace Azure resource ID. Use this ID for AKS oms_agent.log_analytics_workspace_id."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  description = "The workspace customer GUID. This is distinct from the Azure resource ID."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "name" {
  description = "The workspace name."
  value       = azurerm_log_analytics_workspace.this.name
}

output "location" {
  description = "The Azure region of the workspace."
  value       = azurerm_log_analytics_workspace.this.location
}

output "tags" {
  description = "The tags assigned to the workspace."
  value       = azurerm_log_analytics_workspace.this.tags
}

output "primary_shared_key" {
  description = "The primary workspace shared key. Usable only when local authentication is enabled."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "The secondary workspace shared key. Usable only when local authentication is enabled."
  value       = azurerm_log_analytics_workspace.this.secondary_shared_key
  sensitive   = true
}
