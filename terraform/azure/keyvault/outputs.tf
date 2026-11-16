output "id" {
  description = "The Key Vault resource ID, available after the vault creation wait and creator role assignment complete."
  value       = azurerm_key_vault.this.id
  depends_on  = [azurerm_role_assignment.creator]
}

output "creator_role_assignment_id" {
  description = "The vault-scoped Key Vault Administrator role assignment ID for the creator identity."
  value       = azurerm_role_assignment.creator.id
  depends_on  = [azurerm_role_assignment.creator]
}

output "name" {
  description = "The name of the resource."
  value       = azurerm_key_vault.this.name
  depends_on  = [azurerm_role_assignment.creator]
}

output "location" {
  description = "The location of the resource."
  value       = azurerm_key_vault.this.location
  depends_on  = [azurerm_role_assignment.creator]
}

output "tags" {
  description = "The tags of the resource."
  value       = azurerm_key_vault.this.tags
  depends_on  = [azurerm_role_assignment.creator]
}

output "tenant_id" {
  description = "The tenant id of the resource."
  value       = azurerm_key_vault.this.tenant_id
  depends_on  = [azurerm_role_assignment.creator]
}

output "vault_uri" {
  description = "The vault uri of the resource."
  value       = azurerm_key_vault.this.vault_uri
  depends_on  = [azurerm_role_assignment.creator]
}
