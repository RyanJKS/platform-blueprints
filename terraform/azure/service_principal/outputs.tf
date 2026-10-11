output "id" {
  description = "The service principal resource ID."
  value       = azuread_service_principal.this.id
}

output "object_id" {
  description = "The service principal object ID for Azure role assignments."
  value       = azuread_service_principal.this.object_id
}

output "client_id" {
  description = "The application (client) ID of the service principal."
  value       = azuread_application.this.client_id
}

output "display_name" {
  description = "The display name of the service principal."
  value       = azuread_service_principal.this.display_name
}

output "federated_identity_credential_ids" {
  description = "Application federated identity credential resource IDs keyed by credential name."
  value       = { for name, credential in azuread_application_federated_identity_credential.this : name => credential.id }
}

output "client_id_secret_id" {
  description = "The Key Vault secret ID containing the client ID, or null when create_secret is false."
  value       = try(azurerm_key_vault_secret.client_id[0].id, null)
}

output "client_secret_secret_id" {
  description = "The Key Vault secret ID containing the client secret, or null when create_secret is false."
  value       = try(azurerm_key_vault_secret.client_secret[0].id, null)
}
