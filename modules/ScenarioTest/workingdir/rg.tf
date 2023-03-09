module "rg" {
  source = "../modules/rg"
  
  rg_name = var.rg_name
  location = var.location
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
