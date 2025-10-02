terraform {

  required_version = ">= 1.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.39.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.7.0"
    }
  }
}

provider "azurerm" {
  use_cli = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}
