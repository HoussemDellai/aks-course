terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.12.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0.1"
    }
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = "dcef7009-6b94-4382-afdc-17eb160d709a"
  features {}
}

provider "azapi" {
  # Configuration options
}
