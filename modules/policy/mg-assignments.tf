# Deny Public Access - Policy Set Initiative #
resource "azurerm_management_group_policy_assignment" "deny_public_access" {
  count = var.deny_public_access_create == true ? 1 : 0   
  name                 = "customerName - Deny Public Access"
  policy_definition_id = azurerm_policy_set_definition.deny_public_access.id
  management_group_id  = data.azurerm_management_group.customerName.id
  non_compliance_message {
    content = "This action is blocked by 'customerName - Deny Public Access' Azure Policy. Your resource must not be open to the internet, if there is a legit reason then set the tag 'Classification' with value 'Public'."
  }
  parameters = jsonencode({
    effect = {
      value = var.deny_public_access_effect
    }    
  })    
}

# Utilities - Policy Set Initiative #
resource "azurerm_management_group_policy_assignment" "utilities" {
  count = var.utilities_create == true ? 1 : 0   
  name                 = "customerName - Utilities"
  policy_definition_id = azurerm_policy_set_definition.utilities.id
  management_group_id  = data.azurerm_management_group.customerName.id
  non_compliance_message {
    content = "This resource doesn't meet compliance requirements as per Azure Policy - 'customerName - Utilities'."
  }
  parameters = jsonencode({
    effect = {
      value = var.utilities_effect
    }    
  })  
}

# Monitoring - Policy Set Initiative #
# Azure Monitoring Agent #
resource "azurerm_management_group_policy_assignment" "ama" {
  count = var.ama_create == true ? 1 : 0   
  name                 = "Azure Monitoring Agent"
  location             = "uksouth"  
  policy_definition_id = data.azurerm_policy_set_definition.ama.id
  management_group_id  = data.azurerm_management_group.customerName.id
  identity {
    type = "SystemAssigned"
  }   
  parameters = jsonencode({
    bringYourOwnUserAssignedManagedIdentity = {
      value = var.bringYourOwnUserAssignedManagedIdentity
    },
    dcrResourceId = {
      value = var.dcrResourceId
    }    
  })
}

# customerName - Monitoring #
resource "azurerm_management_group_policy_assignment" "monitoring" {
  count = var.monitoring_create == true ? 1 : 0   
  name                 = "customerName - Monitoring"
  location             = "uksouth"
  policy_definition_id = azurerm_policy_set_definition.monitoring.id
  management_group_id  = data.azurerm_management_group.customerName.id
  non_compliance_message {
    content = "This resource doesn't meet compliance requirements as per Azure Policy - 'customerName - Monitoring'."
  }  
  identity {
    type = "SystemAssigned"
  }
  
  parameters = jsonencode({
    logAnalytics = {
      value = var.logAnalytics
    },
    effect = {
      value = var.monitoring_effect
    }    
  })
}

# Security - Policy Set Initiative #
resource "azurerm_management_group_policy_assignment" "security" {
  count = var.security_create == true ? 1 : 0   
  name                 = "customerName - Security"
  location             = "uksouth"  
  policy_definition_id = azurerm_policy_set_definition.security.id
  management_group_id  = data.azurerm_management_group.customerName.id
  non_compliance_message {
    content = "This resource doesn't meet compliance requirements as per Azure Policy - 'customerName - Security'."
  }  
  identity {
    type = "SystemAssigned"
  }  
  parameters = jsonencode({
    effect = {
      value = var.security_effect
    }    
  })    
}

# Governance - Policy Set Initiative #
resource "azurerm_management_group_policy_assignment" "governance" {
  count = var.governance_create == true ? 1 : 0   
  name                 = "customerName - Governance"
  location             = "uksouth"  
  policy_definition_id = azurerm_policy_set_definition.governance.id
  management_group_id  = data.azurerm_management_group.customerName.id
  non_compliance_message {
    content = "This resource doesn't meet compliance requirements as per Azure Policy - 'customerName - Security'."
  }  
  identity {
    type = "SystemAssigned"
  }     
}



# Billing - Policy Set Initiative #
resource "azurerm_management_group_policy_assignment" "billing" {
  count = var.billing_create == true ? 1 : 0   
  name                 = "customerName - Billing"
  location             = "uksouth"  
  policy_definition_id = azurerm_policy_set_definition.billing.id
  management_group_id  = data.azurerm_management_group.customerName.id
  non_compliance_message {
    content = "This resource doesn't meet compliance requirements as per Azure Policy - 'customerName - Billing'."
  }  
  identity {
    type = "SystemAssigned"
  }    
  parameters = jsonencode({
    effect = {
      value = var.billing_effect
    }    
  })  
}
