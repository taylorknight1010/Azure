locals {

rg_name = "rg-adds-dcs-uks"

location = "uksouth"

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
