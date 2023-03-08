module "rg" {
  source = "./modules/rg"
  
  rg_name = local.rg_name
  location = local.location
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
