# Random password generator

resource "random_password" "admin_password1" {
  length           = 30
  special          = true      # Include special characters
  numeric          = true      # Include numbers
  upper            = true      # Include uppercase letters
  lower            = true      # Include lowercase letters
  override_special = "_%@!"    # Customize special characters if needed
  min_special      = 2 #ensure at least one special 
}

resource "random_password" "admin_password2" {
  length           = 30
  special          = true      # Include special characters
  numeric          = true      # Include numbers
  upper            = true      # Include uppercase letters
  lower            = true      # Include lowercase letters
  override_special = "_%@!"    # Customize special characters if needed
  min_special      = 2 #ensure at least one special 
}

# Create users

resource "azuread_user" "bg1" {
  user_principal_name = "user1@${var.domainsuffix}"
  display_name        = "User1"
  password            = random_password.admin_password1.result
  # need to update password to how platform do it and store it in keyvault
}

resource "azuread_user" "bg2" {
  user_principal_name = "user2@${var.domainsuffix}"
  display_name        = "user2"
  password            = random_password.admin_password2.result
  # need to update password to how platform do it and store it in keyvault

}

# Assign Global Admin role

resource "azuread_directory_role" "ga" {
  display_name = "Global administrator"
}

resource "azuread_directory_role_assignment" "ga-bg1" {
  role_id             = azuread_directory_role.ga.template_id
  principal_object_id = azuread_user.bg1.object_id
}

resource "azuread_directory_role_assignment" "ga-bg2" {
  role_id             = azuread_directory_role.ga.template_id
  principal_object_id = azuread_user.bg2.object_id
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

resource "azuread_group" "bg-group" {
  display_name     = "Critical Operations Group"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}

resource "azuread_group_member" "bg1-group-assign" {
  group_object_id  = azuread_group.bg-group.id
  member_object_id = azuread_user.bg1.id
}

resource "azuread_group_member" "bg2-group-assign" {
  group_object_id  = azuread_group.bg-group.id
  member_object_id = azuread_user.bg2.id
}

# Data lookup KV to store creds

data "azurerm_key_vault" "bg" {
  name                = "kv-${var.prefix}-${var.tag_environment}-it"
  resource_group_name = "rg-${var.prefix}-${var.tag_environment}-utilities-uks"
}


# Store passwords in KV

resource "azurerm_key_vault_secret" "user1_password" {
  name         = "user1"
  value        = random_password.admin_password1.result
  key_vault_id = data.azurerm_key_vault.bg.id
}

resource "azurerm_key_vault_secret" "user2_password" {
  name         = "user2"
  value        = random_password.admin_password2.result
  key_vault_id = data.azurerm_key_vault.bg.id
}
