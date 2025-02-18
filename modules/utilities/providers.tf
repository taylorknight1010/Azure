terraform {
  required_providers { 
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.4.0"  
    }
  }
  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
}

