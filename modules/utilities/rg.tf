resource "azurerm_resource_group" "uks" {
  name     = "rg-${var.prefix}-${var.tag_environment}-utilities-uks"
  location = "uksouth"

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }    
}

resource "azurerm_resource_group" "ukw" {
  name     = "rg-${var.prefix}-${var.tag_environment}-utilities-ukw"
  location = "ukwest"

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }  
}

resource "azurerm_management_lock" "uks" {
  name       = "No-Delete"
  scope      = azurerm_resource_group.uks.id
  lock_level = "CanNotDelete"
  notes      = "This Resource Group has a no delete lock enabled"
}

resource "azurerm_management_lock" "ukw" {
  name       = "No-Delete"
  scope      = azurerm_resource_group.ukw.id
  lock_level = "CanNotDelete"
  notes      = "This Resource Group has a no delete lock enabled"
}
