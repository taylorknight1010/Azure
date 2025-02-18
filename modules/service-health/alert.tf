data "azurerm_resource_group" "servicehealthrg" {
  name     = var.servicehealthtargetrg
}

data "azurerm_subscription" "current" {}

data "azurerm_monitor_action_group" "itmailboxag" {
  resource_group_name = var.azurerm_resource_group_itmailboxrg
  name                = "IT Support"
}

resource "azurerm_monitor_action_group" "msmailboxag" {
  name                = "Managed Service Alerts Mailbox"
  resource_group_name = data.azurerm_resource_group.servicehealthrg.name
  short_name          = "msaction"
  location            = var.location

  email_receiver {
    name          = "sendtocs"
    email_address = "managedservicesalerts@customerName.co.uk"
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}

resource "azurerm_monitor_activity_log_alert" "main" {
  name                = var.monitor_activity_log_alert
  resource_group_name = data.azurerm_resource_group.servicehealthrg.name
  scopes              = [data.azurerm_subscription.current.id]
  description         = var.monitor_activity_log_alert_description
  enabled             = "true"
  location            = var.location

  criteria {
    category = "ServiceHealth"
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.itmailboxag.id
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.msmailboxag.id
  }  

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}
