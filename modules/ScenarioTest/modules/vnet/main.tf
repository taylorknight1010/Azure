resource "azurerm_virtual_network" "hubvnet" {
  name                = var.hubvnet
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags  
}

resource "azurerm_subnet" "coresubnet" {
  name                 = var.coresubnet
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hubvnet.name
  address_prefixes     = var.address_prefixes
}

