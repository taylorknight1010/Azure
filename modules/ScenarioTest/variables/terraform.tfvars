rg_name = "rg-adds-dcs-uks"
location = "uksouth"

hubvnet_id = "vnet-core-01"
hubvnet_address_space = ["10.0.0.0/8"]

coresubnet_id = "subnet-core"
coresubnet_address_prefixes = ["10.245.250.0/24"]

nic = "dc01-nic"

vm = "DC01"
vm_size = "Standard_B1ls"
vm_caching = "ReadWrite"
vm_storage_account_type = "Standard_LRS"
vm_publisher = "MicrosoftWindowsServer"
vm_offer = "WindowsServer"
vm_sku = "2019-Datacenter"
vm_osversion = "latest"

vm_names = {
  DC01 = {
    ip_address = "10.245.100.10
}
}

