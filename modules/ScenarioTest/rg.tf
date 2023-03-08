module "rg" {
  source = "./modules/rg"
  name   = var.rg_name
  location = var.rg_location
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
