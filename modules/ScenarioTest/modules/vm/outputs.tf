output "nic" {
  description = "NIC for VM created"
  value       = azurerm_network_interface.hubvnet.name
}

output "vm" {
  description = "virtual machine created"
  value       = azurerm_windows_virtual_machine.coresubnet.name
}
