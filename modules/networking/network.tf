# RGs for both regions

resource "azurerm_resource_group" "network-uks" {
  name     = var.azurerm_resource_group_network_uks
  location = "uksouth"

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name        
  }  
}

resource "azurerm_resource_group" "network-ukw" {
  name     = var.azurerm_resource_group_network_ukw
  location = "ukwest"
  
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }  
}

# NSG

resource "azurerm_network_security_group" "nsg-uks" {
  name                = "nsgcustomerinfrauks"
  location            = azurerm_resource_group.network-uks.location
  resource_group_name = azurerm_resource_group.network-uks.name
  
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }  
}

resource "azurerm_network_security_group" "nsg-ukw" {
  name                = "nsgcustomerinfraukw"
  location            = azurerm_resource_group.network-ukw.location
  resource_group_name = azurerm_resource_group.network-ukw.name
  
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }  
}

# UK South & UK West vnet & subnets

resource "azurerm_virtual_network" "uks" {
  name                = var.azurerm_virtual_network_uks
  location            = azurerm_resource_group.network-uks.location
  resource_group_name = azurerm_resource_group.network-uks.name
  address_space       = ["10.0.2.0/24"]
  dns_servers         = ["10.0.0.4"]

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}

resource "azurerm_subnet" "uks" {
  name                 = "infra-uks"
  resource_group_name  = azurerm_resource_group.network-uks.name
  virtual_network_name = azurerm_virtual_network.uks.name
  address_prefixes     = ["10.0.2.0/26"]
}

resource "azurerm_subnet_network_security_group_association" "uks" {
  subnet_id                 = azurerm_subnet.uks.id
  network_security_group_id = azurerm_network_security_group.nsg-uks.id
}

resource "azurerm_virtual_network" "ukw" {
  name                = var.azurerm_virtual_network_ukw
  location            = azurerm_resource_group.network-ukw.location
  resource_group_name = azurerm_resource_group.network-ukw.name
  address_space       = ["10.0.1.0/24"]
  dns_servers         = ["10.0.0.4"]

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}

resource "azurerm_subnet" "ukw" {
  name                 = "infra-ukw"
  resource_group_name  = azurerm_resource_group.network-ukw.name
  virtual_network_name = azurerm_virtual_network.ukw.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_subnet_network_security_group_association" "ukw" {
  subnet_id                 = azurerm_subnet.ukw.id
  network_security_group_id = azurerm_network_security_group.nsg-ukw.id
}

# Data in existing vnet to peer

data "azurerm_virtual_network" "existing" {
  name                = var.azurerm_virtual_network_existing
  resource_group_name = "customer_Infrastructure"
}

# Data in existing vnet to peer resource group

data "azurerm_resource_group" "existing-vnet" {
  name = "customer_Infrastructure"
}

# Vnet peering uks vnet to existing

resource "azurerm_virtual_network_peering" "uks-existing" {
  name                      = var.azurerm_virtual_network_peering_uks
  resource_group_name       = azurerm_resource_group.network-uks.name
  virtual_network_name      = azurerm_virtual_network.uks.name
  remote_virtual_network_id = data.azurerm_virtual_network.existing.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false   # Only set to true on the existing-to-new peer
  use_remote_gateways          = true    # Allow the new VNet to use the existing VNet's VPN gateway
}

resource "azurerm_virtual_network_peering" "existing-uks" {
  name                      = "existing-uks"
  resource_group_name       = data.azurerm_resource_group.existing-vnet.name
  virtual_network_name      = var.azurerm_virtual_network_existing
  remote_virtual_network_id = azurerm_virtual_network.uks.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = true   # Allow the new VNet to use the existing VNet's VPN gateway
  use_remote_gateways          = false  # The existing VNet does not use the new VNet's gateway
}

# Vnet peering ukw vnet to existing

resource "azurerm_virtual_network_peering" "ukw-existing" {
  name                      = var.azurerm_virtual_network_peering_ukw
  resource_group_name       = azurerm_resource_group.network-ukw.name
  virtual_network_name      = azurerm_virtual_network.ukw.name
  remote_virtual_network_id = data.azurerm_virtual_network.existing.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false   # Only set to true on the existing-to-new peer
  use_remote_gateways          = true    # Allow the new VNet to use the existing VNet's VPN gateway  
}

resource "azurerm_virtual_network_peering" "existing-ukw" {
  name                      = var.azurerm_virtual_network_peering_ukw
  resource_group_name       = data.azurerm_resource_group.existing-vnet.name
  virtual_network_name      = var.azurerm_virtual_network_existing
  remote_virtual_network_id = azurerm_virtual_network.ukw.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = true   # Allow the new VNet to use the existing VNet's VPN gateway
  use_remote_gateways          = false  # The existing VNet does not use the new VNet's gateway  
}


# Azure Bastion UKS

resource "azurerm_subnet" "bastionsubnet-uks" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network-uks.name
  virtual_network_name = azurerm_virtual_network.uks.name
  address_prefixes     = ["10.0.2.64/27"]
}

resource "azurerm_public_ip" "bastion-uks" {
  name                = "vncustomeruks01-bastionpip"
  location            = azurerm_resource_group.network-uks.location
  resource_group_name = azurerm_resource_group.network-uks.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }    
}

resource "azurerm_bastion_host" "bastion-uks" {
  name                = "vncustomeruks01-bastion"
  location            = azurerm_resource_group.network-uks.location
  resource_group_name = azurerm_resource_group.network-uks.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionsubnet-uks.id
    public_ip_address_id = azurerm_public_ip.bastion-uks.id
  }
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }    
}


# Azure Bastion UKW

resource "azurerm_subnet" "bastionsubnet-ukw" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network-ukw.name
  virtual_network_name = azurerm_virtual_network.ukw.name
  address_prefixes     = ["10.0.1.64/27"]
}

resource "azurerm_public_ip" "bastion-ukw" {
  name                = "vncustomerukw01-bastionpip"
  location            = azurerm_resource_group.network-ukw.location
  resource_group_name = azurerm_resource_group.network-ukw.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }    
}

resource "azurerm_bastion_host" "bastion-ukw" {
  name                = "vncustomerukw01-bastion"
  location            = azurerm_resource_group.network-ukw.location
  resource_group_name = azurerm_resource_group.network-ukw.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionsubnet-ukw.id
    public_ip_address_id = azurerm_public_ip.bastion-ukw.id
  }
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }    
}
