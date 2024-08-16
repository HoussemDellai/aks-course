terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "1.15.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

provider "azapi" {
  # Configuration options
}
