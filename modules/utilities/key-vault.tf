# Create Key Vault for user passwords

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "bg" {
  count = var.kv_create == true ? 1 : 0   
  name                = "kv-${var.prefix}-${var.tag_environment}-it"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false
  soft_delete_retention_days  = 30
  public_network_access_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"

    ip_rules = [
      "x.x.x.x",
      "x.x.x.x"
    ]
  }
}

# data "azuread_service_principal" "example" {
#   object_id = var.service_principal_object_id
#   depends_on = [ azurerm_key_vault.bg ]
# }


resource "azurerm_key_vault_access_policy" "example" {
  count = var.kv_create == true ? 1 : 0   
  key_vault_id = azurerm_key_vault.bg[count.index].id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = var.service_principal_object_id


  secret_permissions = [
    "Set",
    "Get",
    "List",
    "Recover",
    "Restore",
    "Purge",
  ]
}

resource "azurerm_monitor_diagnostic_setting" "kv-diag" {
  count = var.kv_create == true ? 1 : 0   
  name               = "kv-logs"
  target_resource_id = azurerm_key_vault.bg[count.index].id
  storage_account_id = azurerm_storage_account.sacustomerNameinfuks[count.index].id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }
}
