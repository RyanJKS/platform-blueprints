output "id" {
  description = "The id of the resource."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "The name of the resource."
  value       = azurerm_virtual_network.this.name
}

output "location" {
  description = "The location of the resource."
  value       = azurerm_virtual_network.this.location
}

output "tags" {
  description = "The tags of the resource."
  value       = azurerm_virtual_network.this.tags
}

output "address_space" {
  description = "The address space of the resource."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Subnet resource IDs keyed by subnet name."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}
