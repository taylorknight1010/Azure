data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "rg_billing" {
  name     = "rg-billing"
  location = "uksouth"
}

resource "azurerm_monitor_action_group" "actiongroup" {
  name                = "actiongroup-monitor"
  resource_group_name = azurerm_resource_group.rg_billing.name
  short_name          = "actiongroup"
}

resource "azurerm_consumption_budget_subscription" "budget" {
  name            = "consumptionbudget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 50
  time_grain = "Monthly"

  time_period {
    start_date = "2023-03-08T00:00:00Z"
    
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        azurerm_resource_group.rg_billing.name,
      ]
    }

    tag {
      name = "money"
      values = [
        "broke",
        "extra broke",
      ]
    }
  }

  notification {
    enabled   = true
    threshold = 90.0
    operator  = "EqualTo"

    contact_emails = [
      "taylorreeseknight@hotmail.com",
    ]

    contact_groups = [
      azurerm_monitor_action_group.actiongroup.id,
    ]

    contact_roles = [
      "Owner",
    ]
  }

  notification {
    enabled        = true
    threshold      = 60.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [
      "taylorreeseknight@hotmail.com",
    ]
  }
}
