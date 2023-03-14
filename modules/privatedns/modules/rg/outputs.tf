#output "resource_group_name" {
 # description = "resource group for dcs"
  #value       = azurerm_resource_group.rg.name
#}

output "resource_group_name" {
  description = "The name of the resource group"
  value = {
    uksouth = azurerm_resource_group.rg.uksouth.name
    ukwest  = azurerm_resource_group.rg.ukwest.name
  }
}
