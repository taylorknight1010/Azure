module "vm" {
  source = "../modules/vm"
  
  nic = local.hubvnet
  location = local.location
  vm = local.coresubnet
  resource_group_name = module.rg.resource_group_name
  coresubnet = module.vnet.coresubnet
  hubvnet = module.vnet.hubvnet
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
