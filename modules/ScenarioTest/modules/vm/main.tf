resource "azurerm_network_interface" "nic" {
  name                = var.nic.id
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.coresubnet
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm.id
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm.size
  admin_username      = "localaccount"
  admin_password      = "Testing123!"
  tags                = var.tags
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = var.vm.os_disk.caching
    storage_account_type = var.vm.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.vm.source_image_reference.publisher
    offer     = var.vm.source_image_reference.offer
    sku       = var.vm.source_image_reference.sku
    version   = var.vm.source_image_reference.verison
  }
}

