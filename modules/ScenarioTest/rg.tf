module "rg" {
  source = "./modules/rg"
  name   = locals.rg_name
  location = locals.location
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
