terraform {

  required_version = ">= 1.2.8"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.99"
    }
  }
}

provider "azurerm" {
  features {}
}
