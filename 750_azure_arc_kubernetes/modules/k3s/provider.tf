#
# Providers Configuration
#

terraform {
  required_version = ">= 1.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.46.0" # "~> 3.8.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}