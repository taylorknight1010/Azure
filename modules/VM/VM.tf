# Resource group creation

resource "azurerm_resource_group" "uks" {
  name     = "rg-${var.prefix}-entraconnect-uks"
  location = "uksouth"
  
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }  
}

resource "azurerm_resource_group" "ukw" {
  name     = "rg-${var.prefix}-entraconnect-ukw"
  location = "ukwest"

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }  
}

# Data in existing subnets

data "azurerm_subnet" "uks" {
  name                 = "infra-uks"
  virtual_network_name = "vnet-customer-uks-01"
  resource_group_name  = "rg-customer-networking-uks"
}

data "azurerm_subnet" "ukw" {
  name                 = "infra-ukw"
  virtual_network_name = "vnet-customer-ukw-01"
  resource_group_name  = "rg-customer-networking-ukw"
}

# Data in key vault info for local admin pw

data "azurerm_key_vault" "example" {
  name                = var.azurerm_key_vault
  resource_group_name = var.kv_resource_group_name
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "localadmin"
  key_vault_id = data.azurerm_key_vault.example.id
}

# Create NICs for UK South VMs 

resource "azurerm_network_interface" "uks" {
  count               = length(var.uks-vms)
  name                = "${var.prefix}-${var.uks-vms[count.index].name}-nic"
  location            = azurerm_resource_group.uks.location
  resource_group_name = azurerm_resource_group.uks.name

  ip_configuration {
    name                          = "${var.prefix}-${var.uks-vms[count.index].name}-nic"
    subnet_id                     = data.azurerm_subnet.uks.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.uks-vms[count.index].ip_address
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }
}

# Create UK South VMs 

resource "azurerm_virtual_machine" "uks" {
  count                = length(var.uks-vms)
  name                 = "${var.uks-vms[count.index].name}"
  location             = azurerm_resource_group.uks.location
  resource_group_name  = azurerm_resource_group.uks.name
  network_interface_ids = [azurerm_network_interface.uks[count.index].id]
  vm_size              = var.vm_size
  # patch_mode = "AutomaticByPlatform"
  # patch_assessment_mode = "AutomaticByPlatform"
  # bypass_platform_safety_checks_on_user_schedule_enabled = true
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  # enable_automatic_updates = false

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-${var.uks-vms[count.index].disk_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.uks-vms[count.index].computer_name}"
    admin_username = "customertestadmin"
    admin_password = data.azurerm_key_vault_secret.admin_password.value
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }
  
  # lifecycle {
  #   ignore_changes = [patch_mode,
  #                     patch_assessment_mode,
  #                     enable_automatic_updates,
  #                     bypass_platform_safety_checks_on_user_schedule_enabled]
  # }  
}

# Create NICs for UK West VMs 

resource "azurerm_network_interface" "ukw" {
  count               = length(var.ukw-vms)
  name                = "${var.prefix}-${var.ukw-vms[count.index].name}-nic"
  location            = azurerm_resource_group.ukw.location
  resource_group_name = azurerm_resource_group.ukw.name

  ip_configuration {
    name                          = "${var.prefix}-${var.ukw-vms[count.index].name}-nic"
    subnet_id                     = data.azurerm_subnet.ukw.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ukw-vms[count.index].ip_address
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }  
}

# Create UK West VMs

resource "azurerm_virtual_machine" "ukw" {
  count                = length(var.ukw-vms)
  name                 = "${var.ukw-vms[count.index].name}"
  location             = azurerm_resource_group.ukw.location
  resource_group_name  = azurerm_resource_group.ukw.name
  network_interface_ids = [azurerm_network_interface.ukw[count.index].id]
  vm_size              = var.vm_size
  # patch_mode = "AutomaticByPlatform"
  # patch_assessment_mode = "AutomaticByPlatform"
  # bypass_platform_safety_checks_on_user_schedule_enabled = true
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  # enable_automatic_updates = false  

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-${var.ukw-vms[count.index].disk_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.ukw-vms[count.index].computer_name}"
    admin_username = "customertestadmin"
    admin_password = data.azurerm_key_vault_secret.admin_password.value
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }  

  # lifecycle {
  #   ignore_changes = [patch_mode,
  #                     patch_assessment_mode,
  #                     enable_automatic_updates,
  #                     bypass_platform_safety_checks_on_user_schedule_enabled]
  # }
}

# Install AMA on UK South & West VMs

resource "azurerm_virtual_machine_extension" "log_analytics_agent_uks" {
  count                      = length(var.uks-vms)  
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_virtual_machine.uks[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.2"
  auto_upgrade_minor_version = true
  tags                       = { managed_by_terraform = true }
  settings = jsonencode({
    workspaceId = var.log_analytics_workspace_id
  })
  protected_settings = jsonencode({
    workspaceKey = var.log_analytics_workspace_key
  })

  depends_on = [azurerm_virtual_machine.uks]  
}

resource "azurerm_virtual_machine_extension" "log_analytics_agent_ukw" {
  count                      = length(var.ukw-vms)    
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_virtual_machine.ukw[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.2"
  auto_upgrade_minor_version = true
  tags                       = { managed_by_terraform = true }
  settings = jsonencode({
    workspaceId = var.log_analytics_workspace_id
  })
  protected_settings = jsonencode({
    workspaceKey = var.log_analytics_workspace_key
  })

  depends_on = [azurerm_virtual_machine.ukw]  
}

# Create Resource Group for Storage Accounts

resource "azurerm_resource_group" "rgsauks" {
  name     = "rg-${var.prefix}-storage-uks"
  location = "uksouth"
  
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }  
}

resource "azurerm_resource_group" "rgsaukw" {
  name     = "rg-${var.prefix}-storage-ukw"
  location = "ukwest"
  
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
  }  
}

# Create storage account in both regions for VM diag logs

resource "azurerm_storage_account" "sacustomerinfuks" {
  name                     = "sacustomerinfuks"
  resource_group_name      = azurerm_resource_group.rgsauks.name
  location                 = azurerm_resource_group.rgsauks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
}
}

resource "azurerm_storage_account" "sacustomerinfukw" {
  name                     = "sacustomerinfukw"
  resource_group_name      = azurerm_resource_group.rgsaukw.name
  location                 = azurerm_resource_group.rgsaukw.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false  

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name    
}
}

# Enable diag settings on all VMs created in code
resource "azurerm_monitor_diagnostic_setting" "uks" {
  count              = length(var.uks-vms)      
  name               = "uks-diag-logs"
  target_resource_id = azurerm_virtual_machine.uks[count.index].id
  storage_account_id = azurerm_storage_account.sacustomerinfuks.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "ukw" {
  count              = length(var.ukw-vms)      
  name               = "ukw-diag-logs"
  target_resource_id = azurerm_virtual_machine.ukw[count.index].id
  storage_account_id = azurerm_storage_account.sacustomerinfukw.id

  metric {
    category = "AllMetrics"
  }
}
