output "nic" {
  description = "virtual network created"
  value       = azurerm_virtual_network.hubvnet.name
}

output "vm" {
  description = "subnet created"
  value       = azurerm_subnet.coresubnet.name
}
