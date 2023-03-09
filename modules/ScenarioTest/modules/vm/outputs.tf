output "nic" {
  description = "virtual network created"
  value       = azurerm_virtual_network.hubvnet.id
}

output "vm" {
  description = "subnet created"
  value       = azurerm_subnet.coresubnet.id
}
