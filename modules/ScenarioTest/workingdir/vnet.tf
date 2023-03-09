module "vnet" {
  source = "../modules/vnet"
  
  hubvnet = local.hubvnet
  location = local.location
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
