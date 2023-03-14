module "privatedns" {
  source = "../modules/privatedns"
  
  resource_group_name = module.rg.resource_group_name
  location = var.location
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
  for_each = dns_zone
  dns_zone = each.key
    
}
