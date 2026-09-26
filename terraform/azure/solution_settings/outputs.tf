output "settings" {
  description = "Shared solution settings, naming values, and the current AzureRM subscription and identity IDs."
  value       = local.settings
}

output "tags" {
  description = "Shared tags for consumers that only need tags."
  value       = var.tags
}
