output "id" {
  description = "The network security group id."
  value       = azurerm_network_security_group.this.id
}

output "name" {
  description = "The network security group name."
  value       = azurerm_network_security_group.this.name
}

output "location" {
  description = "The network security group location."
  value       = azurerm_network_security_group.this.location
}

output "tags" {
  description = "The network security group tags."
  value       = azurerm_network_security_group.this.tags
}

output "rule_ids" {
  description = "Custom security rule resource IDs keyed by rule name."
  value       = { for name, rule in azurerm_network_security_rule.this : name => rule.id }
}

