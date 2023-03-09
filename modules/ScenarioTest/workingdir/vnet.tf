module "vnet" {
  source = "../modules/vnet"
  
  hubvnet = local.hubvnet
  location = local.location
  coresubnet = local.coresubnet
  resource_group_name = module.rg.name
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
