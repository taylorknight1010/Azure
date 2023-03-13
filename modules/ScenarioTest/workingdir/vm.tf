module "vm" {
  source = "../modules/vm"
  resource_group_name = module.rg.resource_group_name
  location = var.location
  nic_id = module.vnet.nic_id
  coresubnet = module.vnet.coresubnet
  vm_names = var.vm_names
  vm_size = var.vm_size
  storage_account_type = var.storage_account_type
  caching = var.caching
  managed_disk_type = var.managed_disk_type
  publisher = var.publisher
  sku = var.sku
  osversion = var.osversion
  offer = var.offer
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }

    }
 

