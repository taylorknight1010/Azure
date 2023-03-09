module "vm" {
  source = "../modules/vm"
  
  nic = local.nic
  location = local.location
  vm = local.coresubnet
  resource_group_name = module.rg.resource_group_name
  coresubnet = module.vnet.coresubnet
  hubvnet = module.vnet.hubvnet
  publisher = local.vm.source_image_reference
  offer     = local.vm.source_image_reference.offer
  sku       = local.vm.source_image_reference.sku
  osversion   = local.vm.source_image_reference.verison  
  caching              = local.vm.os_disk.caching
  storage_account_type = local.vm.os_disk.storage_account_type  
  size                = local.vm.size
  subnet_id                     = module.vnet.coresubnet.id  
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
