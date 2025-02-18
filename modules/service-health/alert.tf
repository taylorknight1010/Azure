data "azurerm_resource_group" "servicehealthrg" {
  name     = "rg-${var.prefix}-${var.tag_environment}-utilities-uks"
}

data "azurerm_subscription" "current" {}

data "azurerm_monitor_action_group" "itmailboxag" {
  name                = "IT Support Mailbox"
  resource_group_name = data.azurerm_resource_group.servicehealthrg.name
}

data "azurerm_monitor_action_group" "msmailboxag" {
  name                = "Managed Service Alerts Mailbox"
  resource_group_name = data.azurerm_resource_group.servicehealthrg.name
}


resource "azurerm_monitor_activity_log_alert" "main" {
  name                = "${var.prefix} - Service Health Alert - ${var.tag_environment}"
  scopes              = [data.azurerm_subscription.current.id]
  resource_group_name = data.azurerm_resource_group.servicehealthrg.name
  description         = "Azure Service Health Alert - All Regions and Services"
  enabled             = true
  location            = "Global"

  criteria {
    category = "ServiceHealth"
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.itmailboxag.id
  }
  
  action {
    action_group_id = data.azurerm_monitor_action_group.msmailboxag.id
  }  

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}
