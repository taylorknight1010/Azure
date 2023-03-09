resource "azurerm_virtual_network" "hubvnet" {
  name                = var.hubvnet.id
  address_space       = var.hubvnet.address_space
  location            = var.hubvnet.location
  resource_group_name = module.resource_group.resource_group_name
}

resource "azurerm_subnet" "coresubnet" {
  name                 = "coresubnet"
  resource_group_name  = module.resource_group.resource_group_name
  virtual_network_name = azurerm_virtual_network.hubvnet.name
  address_prefixes     = var.coresubnet.address_prefixes
}

