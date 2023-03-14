resource_group_name = "rg-privatednszone-uks"
location = "uksouth"
tags = {
    Terraform   = "true"
    Environment = "prod"
  }
dns_zone = {
  "privatelink.blob.windows.core.net" = "blob"
  "privatelink.file.windows.core.net" = "file"
}
