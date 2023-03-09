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

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.vm.id}"
  location              = "${var.vm.location}"
  size                  = "${var.vm.size}"
  storage_account_type  = "${var.vm.storage_account_type}"
  tags                  = var.tags

  storage_os_disk {
    name              = "${var.vm.id}-osdisk"
    caching           = "${var.vm.caching}"
    create_option     = "FromImage"
    managed_disk_type = "${var.vm.storage_account_type}"
  }

  os_profile {
    computer_name  = "${var.vm.id}"
  admin_username   = "localaccount"
  admin_password   = "Testing123!"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  source_image_reference {
    publisher = "${var.vm.publisher}"
    offer     = "${var.vm.offer}"
    sku       = "${var.vm.sku}"
    osversion   = "${var.vm.osversion}"
  }

  network_interface_ids = ["${azurerm_network_interface.nic.id}"]

}
