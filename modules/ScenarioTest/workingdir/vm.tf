module "vm" {
  source = "../modules/vm"
  rg_name = module.rg.resource_group_name
  location = var.location

  hubvnet = {
    id = module.vnet.hubvnet_id
    address_space = module.vnet.hubvnet.address_space
    location = var.location
  }

  coresubnet = {
    id = module.vnet.coresubnet.id
    address_prefixes = module.vnet.coresubnet.address_prefixes
  }

  nic = {
    id = var.nic_id
    tags = {
    Terraform   = "true"
    Environment = "prod"
  }
  }

  vm = {
    id = var.vm_id
    location = var.location
    tags = {
    Terraform   = "true"
    Environment = "prod"
  }
    size = var.vm_size
    caching = var.vm_caching
    storage_account_type = var.vm_storage_account_type
    publisher = var.vm_publisher
    offer = var.vm_offer
    sku = var.vm_sku
    osversion = var.vm_osversion
  }

  vm_names = var.vm_names
}
 

}
