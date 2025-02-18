# Deny Public Access

resource "azurerm_policy_set_definition" "deny_public_access" {
  name         = "customerName-deny-public-access"
  display_name = "customerName - Deny Public Access"
  policy_type  = "Custom"
  description  = "A policy initiative to enforce that storage accounts and Key Vaults and other Azure Resources have disallowed public access unless tagged with Classification: Public."
  parameters = <<PARAMETERS
    {
      "effect": {
        "type": "String",
        "metadata": {
          "displayName": "Policy effect",
          "description": "Effect of the policy."
        },
        "defaultValue": "Disabled",           
        "allowedValues": [
          "Audit",
          "Disabled",
          "Deny"
        ]
      }            
    }
PARAMETERS 
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.storage_account_public_access.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"}
    }
    VALUE
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.keyvault_public_access.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"}
    }
    VALUE
  }
  management_group_id = data.azurerm_management_group.customerName.id    
}

# Utilities

resource "azurerm_policy_set_definition" "utilities" {
  name         = "customerName-utilities"
  display_name = "customerName - Utilities"
  policy_type  = "Custom"
  description  = "A policy initiative to enforce secure score improvements for Azure Virtual Machines."
  parameters = <<PARAMETERS
    {
      "effect": {
        "type": "String",
        "metadata": {
          "displayName": "Policy effect",
          "description": "Effect of the policy."
        },
        "defaultValue": "Disabled",              
        "allowedValues": [
          "Audit",
          "Disabled",
          "Deny"
        ]
      }            
    }
PARAMETERS 
  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.periodic_check.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"}
    }
    VALUE
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.guest_config_ext.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"}
    }
    VALUE
  }  
  management_group_id = data.azurerm_management_group.customerName.id  
}

# Monitoring

resource "azurerm_policy_set_definition" "monitoring" {
  name         = "customerName-monitoring"
  display_name = "customerName - Monitoring"
  policy_type  = "Custom"
  description  = "A policy initiative to enforce monitoring and logging standards across Azure Resource Types."
  management_group_id = data.azurerm_management_group.customerName.id  
  parameters = <<PARAMETERS
    {
      "logAnalytics": {
        "type": "String",
        "metadata": {
          "displayName": "Log Analytics workspace",
          "description": "Log Analytics Workspace where all diagnostic settings will stream too.",
          "portalReview": true
        },
        "defaultValue": "\"\""                   
      },
      "effect": {
        "type": "String",
        "metadata": {
          "displayName": "Policy effect",
          "description": "Effect of the policy."
        },
        "defaultValue": "Disabled",              
        "allowedValues": [
          "DeployIfNotExists",
          "Disabled"
        ]
      },    
      "diagnosticsSettingNameToUse": {
        "type": "String",
        "metadata": {
          "displayName": "Diagnostic setting name",
          "description": "The name of the diagnostic setting."
        },
        "defaultValue": "setByPolicy"        
      },   
      "profileName": {
        "type": "String",
        "metadata": {
          "displayName": "Diagnostic setting name",
          "description": "The name of the diagnostic setting."
        },
        "defaultValue": "setByPolicy"        
      }
    }
PARAMETERS

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.diag-nsg.id
    parameter_values = <<VALUE
      {
        "effect": {"value": "[parameters('effect')]"},
        "diagnosticsSettingNameToUse": {"value": "[parameters('diagnosticsSettingNameToUse')]"},
        "logAnalytics": {"value": "[parameters('logAnalytics')]"},
        "NetworkSecurityGroupEventEnabled": {"value": "True"},
        "NetworkSecurityGroupRuleCounterEnabled": {"value": "True"}
      }
    VALUE
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.diag-kv.id
    parameter_values = <<VALUE
      {
        "effect": {"value": "[parameters('effect')]"},
        "profileName": {"value": "[parameters('profileName')]"},
        "logAnalytics": {"value": "[parameters('logAnalytics')]"},
        "metricsEnabled": {"value": "True"},
        "logsEnabled": {"value": "True"},
        "matchWorkspace": {"value": false}
      }
    VALUE
  }
    policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.diag-sa.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"},
        "profileName": {"value": "[parameters('profileName')]"},
        "logAnalytics": {"value": "[parameters('logAnalytics')]"},
        "metricsEnabled": {"value": true}        
    }
    VALUE
  }  

    policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.diag-avd-ag.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"},
        "logAnalytics": {"value": "[parameters('logAnalytics')]"}
    }
    VALUE
  }  

    policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.diag-avd-hp.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"},
        "logAnalytics": {"value": "[parameters('logAnalytics')]"}
    }
    VALUE
  }

    policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.diag-avd-ws.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"},
        "logAnalytics": {"value": "[parameters('logAnalytics')]"}
    }
    VALUE
  }  

} 

# Security

resource "azurerm_policy_set_definition" "security" {
  name         = "customerName-security"
  display_name = "customerName - Security"
  policy_type  = "Custom"
  description  = "A policy initiative to enforce security standards across Azure Public Cloud."
  parameters = <<PARAMETERS
    {
      "effect": {
        "type": "String",
        "metadata": {
          "displayName": "Policy effect",
          "description": "Effect of the policy."
        },
        "defaultValue": "Disabled",              
        "allowedValues": [
          "AuditIfNotExists",
          "Disabled"
        ]
      }            
    }
PARAMETERS
  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.encryptionathost.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"}
    }
    VALUE
  }
  management_group_id = data.azurerm_management_group.customerName.id  
}


# Governance

resource "azurerm_policy_set_definition" "governance" {
  name         = "customerName-governance"
  display_name = "customerName - Governance"
  policy_type  = "Custom"
  description  = "A policy initiative to enforce governance standards across Azure Public Cloud."
 parameters = <<PARAMETERS
    {
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name",
          "description": "The tag set on resource group and resources."
        },
        "defaultValue": "Owner"
      }               
    }
PARAMETERS

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.require-tag-rg.id
    parameter_values     = <<VALUE
    {
        "tagName": {"value": "[parameters('tagName')]"}
    }
    VALUE
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition_built_in.inherit-tag-rg.id
    parameter_values     = <<VALUE
    {
        "tagName": {"value": "[parameters('tagName')]"}   
    }
    VALUE
  }  

  management_group_id = data.azurerm_management_group.customerName.id
}

# Billing

resource "azurerm_policy_set_definition" "billing" {
  name         = "customerName-billing"
  display_name = "customerName - Billing"
  policy_type  = "Custom"
  description  = "A policy initiative to enforce billing standards across Azure Public Cloud."
  management_group_id = data.azurerm_management_group.customerName.id  
  parameters = <<PARAMETERS
    {
      "effect": {
        "type": "string",
        "metadata": {
          "displayName": "Policy effect",
          "description": "Effect of the policy."
        },
        "allowedValues": [
          "DeployIfNotExists",
          "AuditIfNotExists",
          "Disabled"
        ],
        "defaultValue": "Disabled"        
      }            
    }
PARAMETERS 

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.default_budget.id
    parameter_values     = <<VALUE
    {
        "effect": {"value": "[parameters('effect')]"}   
    }
    VALUE
  }

}



