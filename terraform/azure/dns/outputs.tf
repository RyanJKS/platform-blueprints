output "id" {
  description = "The Azure DNS zone resource ID."
  value       = azurerm_dns_zone.this.id
}

output "name" {
  description = "The DNS zone name."
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "The authoritative Azure nameservers to configure at the registrar or parent zone."
  value       = azurerm_dns_zone.this.name_servers
}

output "tags" {
  description = "Tags assigned to the DNS zone."
  value       = azurerm_dns_zone.this.tags
}
