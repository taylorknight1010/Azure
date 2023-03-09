module "vnet" {
  source = "../modules/vnet"
  
  corevnet = local.corevnet
  location = local.location
  
  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
