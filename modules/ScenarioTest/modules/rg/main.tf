resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.resource_group_location
}
