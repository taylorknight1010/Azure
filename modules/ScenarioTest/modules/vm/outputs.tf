output "nic" {
  description = "virtual network created"
  value       = zurerm_network_interface.hubvnet.name
}

output "vm" {
  description = "subnet created"
  value       = azurerm_virtual_machine.coresubnet.name
}
