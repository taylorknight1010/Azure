module "privatedns" {
  source = "../modules/privatedns"
  
  resource_group_name = module.rg.resource_group_name
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
  dns_zone = each.key
  for_each = {
    uksouth = "uksouth",
    ukwest = "ukwest"
  }
}
