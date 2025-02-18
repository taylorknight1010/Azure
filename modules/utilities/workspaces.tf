# LAW for entra id diag logs - commented out for now as existing customers already setup - uncomment for new managed services customer.
resource "azurerm_log_analytics_workspace" "aad" {
  count = var.law_create == true ? 1 : 0      
  name                = "log-${var.prefix}-${var.tag_environment}-aad"
  location            = azurerm_resource_group.uks.location
  resource_group_name = azurerm_resource_group.uks.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }     
}
