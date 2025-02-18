# Create Recovery Services Vault UK South
resource "azurerm_recovery_services_vault" "uks" {
  count = var.rsv_create == true ? 1 : 0     
  name                = "rsv-${var.prefix}-uks"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location
  sku                 = "Standard"

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }  
}

# Create Recovery Services Vault UK West
resource "azurerm_recovery_services_vault" "ukw" {
  count = var.rsv_create == true ? 1 : 0        
  name                = "rsv-${var.prefix}-ukw"
  resource_group_name = azurerm_resource_group.ukw.name
  location            = azurerm_resource_group.ukw.location
  sku                 = "Standard"

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }    
}

# Create Backup Policy UK South
resource "azurerm_backup_policy_vm" "uks" {
  count = var.rsv_create == true ? 1 : 0        
  name                = "Infra"
  resource_group_name = azurerm_resource_group.uks.name
  recovery_vault_name = azurerm_recovery_services_vault.uks[count.index].name
  instant_restore_retention_days = 2  
  timezone = "GMT Standard Time"

  backup {
    frequency         = "Daily"
    time              = "20:00"
  }

  retention_daily {
    count = 30
  }

}

# Create Backup Policy UK West
resource "azurerm_backup_policy_vm" "ukw" {
  count = var.rsv_create == true ? 1 : 0        
  name                = "Infra"
  resource_group_name = azurerm_resource_group.ukw.name
  recovery_vault_name = azurerm_recovery_services_vault.ukw[count.index].name
  instant_restore_retention_days = 2
  timezone = "GMT Standard Time"  

  backup {
    frequency         = "Daily"
    time              = "20:00"
  }

  retention_daily {
    count = 30
  }

}
