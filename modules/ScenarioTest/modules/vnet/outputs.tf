output "hubvnet" {
  description = "virtual network created"
  value       = azurerm_virtual_network.hubvnet.name
}

output "coresubnet" {
  description = "subnet created"
  value       = azurerm_subnet.coresubnet.name
}
