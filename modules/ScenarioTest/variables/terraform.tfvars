rg_name = "rg-adds-dcs-uks"

location = "uksouth"
  
hubvnet = {
  id = "vnet-core-01"
  address_space = ["10.0.0.0/8"] 
  location = "uksouth"
}
  
  
coresubnet = {
  id = "subnet-core"
  address_prefixes = ["10.245.250.0/24"]
}

nic = {
  id = "dc01-nic"
  
}
  
vm = {
  id = "DC01"
  location = "uksouth"
  size = "Standard_B1ls"
  caching = "ReadWrite"
  storage_account_type = "Standard_LRS"    
  publisher = "MicrosoftWindowsServer"
  offer = "WindowsServer"
  sku = "2019-Datacenter"
  version = "latest"
}  
  
  
vm_names = {
  DC01 = { 
    ip_address = "10.245.100.10"
    sku = "2019-Datacenter"
    data_disk = false
    
  }
  DC02 = { 
    ip_address = "10.245.100.20"
    sku = "2019-Datacenter"
    data_disk = false
    
  }
}

