module "vm" {
  source = "../modules/vm"
  
  nic = local.hubvnet
  location = local.location
  vm = local.coresubnet
  resource_group_name = module.rg.resource_group_name
  coresubnet = module.vnet.coresubnet.id
  hubvnet = module.vnet.hubvnet.id
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
