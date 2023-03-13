module "rg" {
  source = "../modules/rg"
  
  rg_name = var.resource_group_name
  location = var.location
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
