module "rg" {
  source = "../modules/rg"
  
  for_each = {
    uksouth = "uksouth",
    ukwest = "ukwest"
  }
  resource_group_name = each.key
  location = each.value
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
