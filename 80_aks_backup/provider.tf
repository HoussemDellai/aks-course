terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.48.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}