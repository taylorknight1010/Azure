# Create Resource Group for Storage Accounts

# Create storage account in both regions for VM diag logs

resource "azurerm_storage_account" "sacustomerNameinfuks" {
  count = var.storage_create == true ? 1 : 0      
  name                     = "sa${var.prefix}${var.tag_environment}utilitiesuks"
  resource_group_name      = azurerm_resource_group.uks.name
  location                 = azurerm_resource_group.uks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
}
}

# resource "azurerm_storage_account" "sacustomerNameinfukw" {
#   count = var.storage_create == true ? 1 : 0      
#   name                     = "sa${var.prefix}${var.tag_environment}utilitiesukw"
#   resource_group_name      = azurerm_resource_group.ukw.name
#   location                 = azurerm_resource_group.ukw.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   public_network_access_enabled = false  

#   tags = {
#     environment  = var.tag_environment
#     managed_by_terraform = "true"
#     pipeline_name = var.pipeline_name    
# }
# }

#comment back in when required
