output "nic" {
  description = "NIC for VM created"
  value       = azurerm_network_interface.nic_id.name
}

output "vm" {
  description = "virtual machine created"
  value       = azurerm_windows_virtual_machine.vm_names.name
}
