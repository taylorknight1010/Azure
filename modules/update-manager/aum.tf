data "azurerm_resource_group" "patchingrg" {
  name     = "rg-${var.prefix}-${var.tag_environment}-utilities-uks"
}

data "azurerm_resource_group" "dynamicscopetargetrg" {
  name     = var.dynamicscopetargetrg
}

resource "azurerm_maintenance_configuration" "weds-maintenance" {
  count = var.create-weds-maintenance == true ? 1 : 0

  name                     = "${var.tag_environment} Wednesday Maintenance"
  resource_group_name      = data.azurerm_resource_group.patchingrg.name
  location                 = data.azurerm_resource_group.patchingrg.location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  window {
    start_date_time = var.weds-maintenance-start_date_time
    time_zone       = var.weds-maintenance-time_zone
    recur_every     = var.weds-maintenance-recurrence
    duration        = var.weds-maintenance-duration
  }

  install_patches {
    reboot = "IfRequired"

    windows {
      classifications_to_include = ["Critical","Security","Updates"]
      kb_numbers_to_exclude      = []
      kb_numbers_to_include      = []
    }
  }    

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  }    
}

resource "azurerm_maintenance_assignment_dynamic_scope" "weds-maintenance-dynamicscope" {
  count = var.create-weds-maintenance == true ? 1 : 0

  name                         = "${var.tag_environment} Wednesday Maintenance DS"
  maintenance_configuration_id = azurerm_maintenance_configuration.weds-maintenance[count.index].id

  filter {
    locations       = ["uksouth"]
    os_types        = ["Windows"]
    resource_groups = [data.azurerm_resource_group.dynamicscopetargetrg.name]
    resource_types  = ["Microsoft.Compute/virtualMachines"]
    tag_filter      = "Any"
    tags {
      tag    = "role"
      values = var.role_tag_values
    }
  }    
}

resource "azurerm_maintenance_configuration" "weds-maintenance-update-only" {
  count = var.create-weds-maintenance-only == true ? 1 : 0

  name                     = "${var.tag_environment} Wednesday Maintenance Update Only"
  resource_group_name      = data.azurerm_resource_group.patchingrg.name
  location                 = data.azurerm_resource_group.patchingrg.location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  window {
    start_date_time = var.weds-maintenance-only-start_date_time
    time_zone       = var.weds-maintenance-only-time_zone
    recur_every     = var.weds-maintenance-only-recurrence
    duration        = var.weds-maintenance-only-duration
  }

  install_patches {
    reboot = "Never"

    windows {
      classifications_to_include = ["Critical","Security","UpdateRollup","Updates"]
      kb_numbers_to_exclude      = []
      kb_numbers_to_include      = []
    }
  }
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  } 
}

resource "azurerm_maintenance_assignment_dynamic_scope" "weds-maintenance-only-dynamicscope" {
  count = var.create-weds-maintenance-only == true ? 1 : 0

  name                         = "${var.tag_environment} Wednesday Maintenance Update Only DS"
  maintenance_configuration_id = azurerm_maintenance_configuration.weds-maintenance-update-only[count.index].id

  filter {
    locations       = ["uksouth"]
    os_types        = ["Windows"]
    resource_groups = [data.azurerm_resource_group.dynamicscopetargetrg.name]
    resource_types  = ["Microsoft.Compute/virtualMachines"]
    tag_filter      = "Any"
    tags {
      tag    = "role"
      values = var.role_tag_values
    }    
  }
}

resource "azurerm_maintenance_configuration" "definition-updates" {
  count = var.create-definition-updates == true ? 1 : 0

  name                     = "${var.tag_environment} Definition Updates"
  resource_group_name      = data.azurerm_resource_group.patchingrg.name
  location                 = data.azurerm_resource_group.patchingrg.location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  window {
    start_date_time = var.definition-updates-start_date_time
    time_zone       = var.definition-updates-time_zone
    recur_every     = var.definition-updates-recurrence
    duration        = var.definition-updates-duration
  }

  install_patches {
    reboot = "IfRequired"

    windows {
      classifications_to_include = ["Definition"]
      kb_numbers_to_exclude      = []
      kb_numbers_to_include      = []
    }
  }
  
  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  } 
}

resource "azurerm_maintenance_assignment_dynamic_scope" "definitionupdates-dynamicscope" {
  count = var.create-definition-updates == true ? 1 : 0

  name                         = "${var.tag_environment} Definition Updates DS"
  maintenance_configuration_id = azurerm_maintenance_configuration.definition-updates[count.index].id

  filter {
    locations       = ["uksouth"]
    os_types        = ["Windows"]
    resource_groups = [data.azurerm_resource_group.dynamicscopetargetrg.name]
    resource_types  = ["Microsoft.Compute/virtualMachines"]
    tag_filter      = "Any"
    tags {
      tag    = "role"
      values = var.role_tag_values
    }    
  }
}

resource "azurerm_maintenance_configuration" "image-updates" {
  count = var.create-image-updates == true ? 1 : 0

  name                     = "${var.tag_environment} Image Updates"
  resource_group_name      = data.azurerm_resource_group.patchingrg.name
  location                 = data.azurerm_resource_group.patchingrg.location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  window {
    start_date_time = var.image-updates-start_date_time
    time_zone       = var.image-updates-time_zone
    recur_every     = var.image-updates-recurrence
    duration        = var.image-updates-duration
  }

  install_patches {
    reboot = "IfRequired"

    windows {
      classifications_to_include = ["Critical","Security","Updates"]
      kb_numbers_to_exclude      = []
      kb_numbers_to_include      = []
    }
  }

  tags = {
    environment  = var.tag_environment
    managed_by_terraform = "true"
    pipeline_name = var.pipeline_name
  } 
}

resource "azurerm_maintenance_assignment_dynamic_scope" "imageserver-dynamicscope" {
  count = var.create-image-updates == true ? 1 : 0

  name                         = "${var.tag_environment} Image Updates DS"
  maintenance_configuration_id = azurerm_maintenance_configuration.image-updates[count.index].id

  filter {
    locations       = ["uksouth"]
    os_types        = ["Windows"]
    resource_groups = [data.azurerm_resource_group.dynamicscopetargetrg.name]
    resource_types  = ["Microsoft.Compute/virtualMachines"]
    tag_filter      = "Any"
    tags {
      tag    = "role"
      values = ["image_server"]
    }        
  }
}
