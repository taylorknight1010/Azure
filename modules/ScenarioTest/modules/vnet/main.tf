resource "azurerm_virtual_network" "hubvnet" {
  name                = var.hubvnet.id
  address_space       = var.hubvnet.address_space
  location            = var.hubvnet.location
  resource_group_name = azurerm_resource_group.resources_rg.name
}

resource "azurerm_subnet" "resources_subnet_vnet" {
  name                 = "resources"
  resource_group_name  = azurerm_resource_group.resources_rg.name
  virtual_network_name = azurerm_virtual_network.primary_vnet.name
  address_prefixes     = ["10.0.250.0/24"]
}

