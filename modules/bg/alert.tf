data "azurerm_monitor_action_group" "ITSupport" {
  name                = "IT Support Mailbox"
  resource_group_name = "rg-${var.prefix}-${var.tag_environment}-utilities-uks"
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "breakglass_signin_alert" {
  name                = "breakglass-signin-alert"
  resource_group_name = "rg-${var.prefix}-${var.tag_environment}-utilities-uks"
  location            = "UK South"
  description         = "Alert for sign-ins by users in the Breakglass Users."
  enabled             = true
  severity            = 0

  # Scope: Define where to run the query, typically the Log Analytics workspace
  scopes              = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT1M" # Frequency for evaluating the query
  window_duration      = "PT1M" # Duration to aggregate data

  criteria {
    query                   = <<-QUERY
SigninLogs
| where UserPrincipalName == 'user2@${var.domainsuffix}' or UserPrincipalName == 'user1@${var.domainsuffix}'
QUERY
    time_aggregation_method = "Count" # Aggregate the data as count
    threshold               = 0
    operator                = "GreaterThan"

    resource_id_column    = "UserPrincipalName"
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [data.azurerm_monitor_action_group.ITSupport.id]
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }
}


