module "vnet" {
  source = "../modules/vnet"
  
  hubvnet = var.hubvnet
  location = var.location
  coresubnet = var.coresubnet
  resource_group_name = module.rg.resource_group_name
  address_space = var.address_space
  address_prefixes = var.address_prefixes
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
