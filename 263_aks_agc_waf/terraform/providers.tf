terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azapi  = { source = "Azure/azapi" }
  }
}
provider "azurerm" { features {} }
provider "azapi" {}
