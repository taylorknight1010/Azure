resource_group_name = "rg-adds-dcs-uks"
location = "uksouth"

hubvnet = "vnet-core-01"
address_space = ["10.0.0.0/8"]

coresubnet = "subnet-core"
address_prefixes = ["10.245.250.0/24"]

nic_id = "dc01-nic"
managed_disk_type = "Standard_LRS"
vm_names = ["dc01", "dc02"]
vm_size = "Standard_B1ls"
caching = "ReadWrite"
storage_account_type = "Standard_LRS"
publisher = "MicrosoftWindowsServer"
offer = "WindowsServer"
sku = "2019-Datacenter"
osversion = "latest"

tags = {
    Terraform   = "true"
    Environment = "prod"
  }

