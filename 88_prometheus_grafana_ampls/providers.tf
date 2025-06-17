terraform {

  required_version = ">= 1.11"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.32.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Configure the Azure Active Directory Provider
provider "azuread" { # default takes current user/identity tenant
}

provider "azapi" {
  # Configuration options
}
