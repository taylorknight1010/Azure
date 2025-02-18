resource "azurerm_eventgrid_system_topic" "aum_system_topic" {
  count = var.create-image-updates == true ? 1 : 0  
  name                      = "aum-system-topic-image"
  resource_group_name       = data.azurerm_resource_group.patchingrg.name
  location                  = data.azurerm_resource_group.patchingrg.location
  source_arm_resource_id    = azurerm_maintenance_configuration.image-updates[count.index].id
  topic_type                = "Microsoft.Maintenance.MaintenanceConfigurations"
}

data "azurerm_subscription" "primary" {}

resource "azurerm_eventgrid_system_topic_event_subscription" "post" {
  count = var.create-image-updates == true ? 1 : 0    
  name                = "aum-image-event-subscription-post"
  system_topic        = azurerm_eventgrid_system_topic.aum_system_topic[count.index].name
  resource_group_name = data.azurerm_resource_group.patchingrg.name

  included_event_types = [
    "Microsoft.Maintenance.PostMaintenanceEvent"
  ]
  
  webhook_endpoint {
    url = azurerm_automation_webhook.post[count.index].uri    
  }
}

resource "azurerm_eventgrid_system_topic_event_subscription" "pre" {
  count = var.ppd_pre_event_create == true ? 1 : 0    
  name                = "aum-image-event-subscription-pre"
  system_topic        = azurerm_eventgrid_system_topic.aum_system_topic[count.index].name
  resource_group_name = data.azurerm_resource_group.patchingrg.name

  included_event_types = [
    "Microsoft.Maintenance.PreMaintenanceEvent"
  ]
  
  webhook_endpoint {
    url = azurerm_automation_webhook.pre[count.index].uri    
  }
}

data "azurerm_automation_account" "automation" {
  count = var.create-image-updates == true ? 1 : 0    
  name                = "aa-maintenance-${var.tag_environment}"
  resource_group_name = data.azurerm_resource_group.dynamicscopetargetrg.name
}

data "azurerm_automation_runbook" "image_runbook" {
  count = var.create-image-updates == true ? 1 : 0    
  name                    = "CreateImage"
  resource_group_name     = data.azurerm_resource_group.dynamicscopetargetrg.name
  automation_account_name = data.azurerm_automation_account.automation[count.index].name
}

data "azurerm_automation_runbook" "poweron_runbook" {
  count = var.ppd_pre_event_create == true ? 1 : 0    
  name                    = "PowerOn-PPD"
  resource_group_name     = data.azurerm_resource_group.dynamicscopetargetrg.name
  automation_account_name = data.azurerm_automation_account.automation[count.index].name
}

resource "azurerm_automation_webhook" "post" {
  count = var.create-image-updates == true ? 1 : 0  
  name                    = "AVD-Create-Image-Webhook"
  resource_group_name     = data.azurerm_resource_group.dynamicscopetargetrg.name
  automation_account_name = data.azurerm_automation_account.automation[count.index].name
  expiry_time             = var.webhook_expiry_date
  enabled                 = true
  runbook_name            = data.azurerm_automation_runbook.image_runbook[count.index].name
}

resource "azurerm_automation_webhook" "pre" {
  count = var.ppd_pre_event_create == true ? 1 : 0  
  name                    = "AVD-Create-Image-Webhook-Pre"
  resource_group_name     = data.azurerm_resource_group.dynamicscopetargetrg.name
  automation_account_name = data.azurerm_automation_account.automation[count.index].name
  expiry_time             = var.webhook_expiry_date
  enabled                 = true
  runbook_name            = data.azurerm_automation_runbook.poweron_runbook[count.index].name
}
