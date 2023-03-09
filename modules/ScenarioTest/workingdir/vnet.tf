module "rg" {
  source = "../modules/rg"
  }
}

module "vnet" {
  source = "../modules/vnet"
  
  hubvnet = local.hubvnet
  location = local.location
  coresubnet = local.coresubnet
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
