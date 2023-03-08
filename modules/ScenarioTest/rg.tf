module "rg" {
  source = "./modules/rg"
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
