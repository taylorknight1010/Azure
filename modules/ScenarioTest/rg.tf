module "rg" {
  source = "./modules/rg"
  name   = local.rg_name
  location = local.location
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
