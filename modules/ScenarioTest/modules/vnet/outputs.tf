output "hubvnet" {
  description = "virtual network created"
  value       = azurerm_virtual_network.hubvnet
}

output "coresubnet" {
  description = "subnet created"
  value       = azurerm_subnet.coresubnet
}
