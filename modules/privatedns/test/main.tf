terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.47.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

# Load variables from .tfvars file
variable "domain_list" {
  type = list(string)
}

variable "region_list" {
  type = list(string)
}

# Create resource groups in each region
resource "azurerm_resource_group" "rg" {
  count    = length(var.region_list)
  name     = "${var.region_list[count.index]}-rg"
  location = var.region_list[count.index]
}

# Create private DNS zones in each resource group for each domain
resource "azurerm_private_dns_zone" "dns_zone" {
  for_each = {
    for domain in var.domain_list :
    domain => [for i in range(length(var.region_list)) : azurerm_resource_group.rg[i].name]
  }

  name                = each.key
  resource_group_name = each.value[count.index]

  count = length(each.value)
}
