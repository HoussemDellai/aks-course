terraform {

  required_version = ">= 1.14.0"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.66.0"
    }
  }
}

provider "azurerm" {
  features {}
}