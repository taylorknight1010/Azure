terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.50.0"
    }
    
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.106.1"  
    }
  }
  backend "azurerm" {
    use_azuread_auth = true
  }
}
