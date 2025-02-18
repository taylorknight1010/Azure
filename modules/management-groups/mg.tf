# Tenant Root Group
# customerName
resource "azurerm_management_group" "customerName" {
  display_name = "customerName"

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
}

# Tenant Root Group - customerName - Decom
resource "azurerm_management_group" "customerName_decom" {
  display_name               = "decom"
  parent_management_group_id = azurerm_management_group.customerName.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}

# Tenant Root Group - customerName - Sandbox
resource "azurerm_management_group" "customerName_sandbox" {
  display_name               = "sandbox"
  parent_management_group_id = azurerm_management_group.customerName.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}

# Tenant Root Group - customerName - Platform
resource "azurerm_management_group" "customerName_platform" {
  display_name               = "platform"
  parent_management_group_id = azurerm_management_group.customerName.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}

# Tenant Root Group - customerName - Platform - Connectivity
resource "azurerm_management_group" "customerName_platform_connectivity" {
  display_name               = "connectivity"
  parent_management_group_id = azurerm_management_group.customerName_platform.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}

# Tenant Root Group - customerName - Landing Zones
resource "azurerm_management_group" "customerName_lz" {
  display_name               = "landing-zones"
  parent_management_group_id = azurerm_management_group.customerName.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}

# Tenant Root Group - customerName - Landing Zones - Prod
resource "azurerm_management_group" "customerName_lz_prod" {
  display_name               = "prod"
  parent_management_group_id = azurerm_management_group.customerName_lz.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}

# Tenant Root Group - customerName - Landing Zones - Non Prod
resource "azurerm_management_group" "customerName_lz_nonprod" {
  display_name               = "non-prod"
  parent_management_group_id = azurerm_management_group.customerName_lz.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}

# Tenant Root Group - customerName - Landing Zones - Billing
resource "azurerm_management_group" "customerName_lz_billing" {
  display_name               = "billing"
  parent_management_group_id = azurerm_management_group.customerName_lz.id

#   subscription_ids = [
#     data.azurerm_subscription.current.subscription_id,
#   ]
  # other subscription IDs can go here
}
