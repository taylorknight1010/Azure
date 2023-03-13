resource "azurerm_network_interface" "nic" {
  name                = var.nic_id
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.coresubnet
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = var.vm_names
  location              = var.location
  size                  = var.vm_size
  storage_account_type  = var.storage_account_type
  tags                  = var.tags

  storage_os_disk {
    name              = var.vm_names
    caching           = var.caching
    create_option     = "FromImage"
    managed_disk_type = var.managed_disk_type
  }

  os_profile {
    computer_name  = var.vm_names
  admin_username   = "localaccount"
  admin_password   = "Testing123!"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    osversion   = var.osversion
  }
network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

}
