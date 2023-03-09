resource "azurerm_virtual_network" "hubvnet" {
  name                = var.hubvnet.id
  address_space       = var.hubvnet.address_space
  location            = var.hubvnet.location
  resource_group_name = var.resource_group_name.name
  tags                = var.tags  
}

resource "azurerm_subnet" "coresubnet" {
  name                 = var.coresubnet.id
  resource_group_name  = var.resource_group_name.name
  virtual_network_name = azurerm_virtual_network.hubvnet.name
  address_prefixes     = var.coresubnet.address_prefixes
}

