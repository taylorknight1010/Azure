resource_group_name = "rg-privatednszone-uks"
location = "uksouth"
tags = {
    Terraform   = "true"
    Environment = "prod"
  }
dns_zone = {
  "blob" = ["privatelink.blob.windows.core.net"],
  "file" = ["privatelink.file.windows.core.net"],
}
