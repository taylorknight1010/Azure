### Azure Policy Definitions ###


#################################################################################### Utilities ######################################################################################
## Machines should be configured to periodically check for missing system updates ##
data "azurerm_policy_definition_built_in" "periodic_check" {
  display_name = "Machines should be configured to periodically check for missing system updates"
}

## Virtual machines' Guest Configuration extension should be deployed with system-assigned managed identity ##
data "azurerm_policy_definition_built_in" "guest_config_ext" {
  display_name = "Virtual machines' Guest Configuration extension should be deployed with system-assigned managed identity"
}

#################################################################################### Goverenance ####################################################################################
## Require a tag on resource Groups ##
data "azurerm_policy_definition_built_in" "require-tag-rg" {
  display_name = "Require a tag on resource groups"
}

## Inherit a tag from the resource group if missing ##
data "azurerm_policy_definition_built_in" "inherit-tag-rg" {
  display_name = "Inherit a tag from the resource group if missing"
}

#################################################################################### Security ######################################################################################
## Windows virtual machines should enable Azure Disk Encryption or EncryptionAtHost. ##
data "azurerm_policy_definition_built_in" "encryptionathost" {
  display_name = "Windows virtual machines should enable Azure Disk Encryption or EncryptionAtHost."
}

#################################################################################### Monitoring ####################################################################################
## Enable Azure Monitor for VMs with Azure Monitoring Agent(AMA) ##
data "azurerm_policy_set_definition" "ama" {
  display_name = "Enable Azure Monitor for VMs with Azure Monitoring Agent(AMA)"
}

## Configure diagnostic settings for Azure Network Security Groups to Log Analytics workspace ##
data "azurerm_policy_definition_built_in" "diag-nsg" {
  display_name = "Configure diagnostic settings for Azure Network Security Groups to Log Analytics workspace"
}

## Deploy Diagnostic Settings for Key Vault to Log Analytics workspace ##
data "azurerm_policy_definition_built_in" "diag-kv" {
  display_name = "Deploy Diagnostic Settings for Key Vault to Log Analytics workspace"
}

## Configure diagnostic settings for Storage Accounts to Log Analytics workspace ##
data "azurerm_policy_definition_built_in" "diag-sa" {
  display_name = "Configure diagnostic settings for Storage Accounts to Log Analytics workspace"
}

## Enable logging by category group for Application groups (microsoft.desktopvirtualization/applicationgroups) to Log Analytics ##
data "azurerm_policy_definition_built_in" "diag-avd-ag" {
  display_name = "Enable logging by category group for Application groups (microsoft.desktopvirtualization/applicationgroups) to Log Analytics"
}

## Enable logging by category group for Host pool (microsoft.desktopvirtualization/hostpools) to Log Analytics ##
data "azurerm_policy_definition_built_in" "diag-avd-hp" {
  display_name = "Enable logging by category group for Host pools (microsoft.desktopvirtualization/hostpools) to Log Analytics"
}

## Enable logging by category group for Workspace (microsoft.desktopvirtualization/workspaces) to Log Analytics ##
data "azurerm_policy_definition_built_in" "diag-avd-ws" {
  display_name = "Enable logging by category group for Workspaces (microsoft.desktopvirtualization/workspaces) to Log Analytics"
}

#################################################################################### Billing ####################################################################################



##################################################################################### Management Groups ############################################################################

data "azurerm_management_group" "customerName" {
  display_name = "customerName"
}

data "azurerm_management_group" "lz" {
  display_name = "landing-zones"
}

data "azurerm_management_group" "nonprod" {
  display_name = "non-prod"
}

data "azurerm_management_group" "prod" {
  display_name = "prod"
}

data "azurerm_management_group" "platform" {
  display_name = "platform"
}

data "azurerm_management_group" "connectivity" {
  display_name = "connectivity"
}
