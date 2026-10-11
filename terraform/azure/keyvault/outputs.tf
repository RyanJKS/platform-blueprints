output "id" {
  description = "The Key Vault resource ID, available after the creator role assignment completes."
  value       = azurerm_key_vault.this.id
  depends_on  = [azurerm_role_assignment.creator]
}

output "creator_role_assignment_id" {
  description = "The vault-scoped Key Vault Administrator role assignment ID for the creator identity."
  value       = azurerm_role_assignment.creator.id
}

output "name" {
  description = "The name of the resource."
  value       = azurerm_key_vault.this.name
}

output "location" {
  description = "The location of the resource."
  value       = azurerm_key_vault.this.location
}

output "tags" {
  description = "The tags of the resource."
  value       = azurerm_key_vault.this.tags
}

output "tenant_id" {
  description = "The tenant id of the resource."
  value       = azurerm_key_vault.this.tenant_id
}

output "vault_uri" {
  description = "The vault uri of the resource."
  value       = azurerm_key_vault.this.vault_uri
}
