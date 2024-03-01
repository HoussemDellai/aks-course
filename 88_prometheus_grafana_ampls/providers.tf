terraform {

  required_version = ">= 1.2.8"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.94.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "= 2.47.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Configure the Azure Active Directory Provider
provider "azuread" { # default takes current user/identity tenant
}
