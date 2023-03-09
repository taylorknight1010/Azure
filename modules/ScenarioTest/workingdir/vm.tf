module "vm" {
  source = "../modules/vm"
  
  nic = var.nic
  location = var.location
  vm = var.vm
  resource_group_name = module.rg.resource_group_name
  coresubnet = module.vnet.coresubnet
  hubvnet = module.vnet.hubvnet
  publisher = var.vm.publisher
  offer     = var.vm.offer
  sku       = var.vm.sku
  caching              = var.vm.caching
  storage_account_type = var.vm.storage_account_type  
  size                = var.vm.size
  osversion = var.osversion
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
