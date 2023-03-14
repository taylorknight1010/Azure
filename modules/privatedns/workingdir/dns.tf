module "privatedns" {
  source = "../modules/privatedns"
  
  resource_group_name = module.rg.resource_group_name
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
  for_each = var.dns_zone
  dns_zone = each.key
    
}
