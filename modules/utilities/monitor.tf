# Action Group for Managed Services
resource "azurerm_monitor_action_group" "msmailboxag" {
  count = var.monitor_create == true ? 1 : 0   
  name                = "Managed Service Alerts Mailbox"
  resource_group_name = azurerm_resource_group.uks.name
  short_name          = "msaction"

  email_receiver {
    name          = "send-email"
    email_address = "email@customerName.co.uk"
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}

# Action Group for IT
resource "azurerm_monitor_action_group" "itmailboxag" {
  count = var.monitor_create == true ? 1 : 0    
  name                = "IT Support Mailbox"
  resource_group_name = azurerm_resource_group.uks.name
  short_name          = "itaction"

  email_receiver {
    name          = "sendtoit"
    email_address = "itsupport@customerName.co.uk"
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}

# data in existing workspace that stores Entra ID logs
# data "azurerm_log_analytics_workspace" "aad" {
#   name                = var.log_analytics_workspace_name
#   resource_group_name = var.log_analytics_workspace_rg
# }

# Azure Monitor Log Alert for changes in Conditional Access Policies
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cap_change_alert" {
  count = var.alerts_create == true ? 1 : 0    
  name                = "conditional-access-changes-alert"
  resource_group_name = azurerm_resource_group.uks.name
  location            = "UK South"
  description         = "Alert for any changes to Conditional Access Policies."
  enabled             = true
  severity            = 1

  # Scope: Define where to run the query, typically the Log Analytics workspace
  scopes              = [azurerm_log_analytics_workspace.aad[count.index].id]

  evaluation_frequency = "PT5M" # Frequency for evaluating the query
  window_duration      = "PT5M" # Duration to aggregate data

  criteria {
    query                   = <<-QUERY
AuditLogs
| where Category == "Policy" and ActivityDisplayName contains "Conditional Access policy"
| where OperationName in ("Update conditional access policy", "Add conditional access policy", "Delete conditional access policy")
| extend TargetResources = parse_json(tostring(TargetResources))
| extend ModifiedProperties = parse_json(tostring(TargetResources[0].modifiedProperties))
| mv-expand ModifiedProperty = ModifiedProperties
| project TimeGenerated, 
          CAP = tostring(TargetResources[0].displayName),
          OldValue = tostring(ModifiedProperty.oldValue), 
          NewValue = tostring(ModifiedProperty.newValue), 
          PolicyId = tostring(TargetResources[0].id),  // Adjust if the Policy ID is located differently
          User = tostring(InitiatedBy.user.userPrincipalName),
          OperationName
| order by TimeGenerated desc
QUERY
    time_aggregation_method = "Count" # Aggregate the data as count
    threshold               = 0
    operator                = "GreaterThan"
    
  }

  action {
    action_groups = [azurerm_monitor_action_group.itmailboxag[count.index].id]
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}
