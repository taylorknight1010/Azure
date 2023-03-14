resource_group_name = {
  "rg-privatednszone-uks" = "rg-privatednszone-uks"
  "rg-privatednszone-ukw" = "rg-privatednszone-ukw"
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
