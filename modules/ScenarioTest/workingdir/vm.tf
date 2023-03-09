module "vm" {
  source = "../modules/vm"
  
  nic = local.nic
  location = local.location
  vm = local.vm
  resource_group_name = module.rg.resource_group_name
  coresubnet = module.vnet.coresubnet
  hubvnet = module.vnet.hubvnet
  publisher = local.vm.publisher
  offer     = local.vm.offer
  sku       = local.vm.sku
  osversion   = local.vm.verison  
  caching              = local.vm.caching
  storage_account_type = local.vm.storage_account_type  
  size                = local.vm.size
  
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
