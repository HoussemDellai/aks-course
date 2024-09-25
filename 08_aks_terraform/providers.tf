provider "azurerm" {
  subscription_id = "38977b70-47bf-4da5-a492-88712fce8725"
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.3.0"
    }
  }
}
