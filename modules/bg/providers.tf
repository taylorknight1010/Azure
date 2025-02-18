terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
    
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.0.1"  
    }

    random = {
      source = "hashicorp/random"
      version = "3.6.3"
    }

  }
  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azuread" {
  # Configuration options
}

provider "azurerm" {
  features {}
}

provider "random" {
  # Configuration options
}
