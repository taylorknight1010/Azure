terraform {
  required_providers { 
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.112.0"  
    }
  }
  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
}
