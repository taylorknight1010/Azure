module "vnet" {
  source = "../modules/vnet"
  
  hubvnet = local.hubvnet
  location = local.location
  coresubnet = local.coresubnet
  resource_group_name = module.rg.resource_group_name
  address_space = local.hubvnet.address_space
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
