resource_group_name = {
  "uksouth" = "rg-privatednszone-uks"
  "ukwest" = "rg-privatednszone-ukw"
}
location = {
  "uksouth" = "uksouth"
  "ukwest" = "ukwest"
}
tags = {
    Terraform   = "true"
    Environment = "prod"
  }
dns_zone = {
  "privatelink.blob.windows.core.net" = "blob"
  "privatelink.file.windows.core.net" = "file"
}
