terraform {

  required_version = ">= 1.2.8"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.2.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "38977b70-47bf-4da5-a492-88712fce8725"
  # subscription_id = "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxx" # required otherwise use env ARM_SUBSCRIPTION_ID 
  features {}
}

data "azurerm_client_config" "current" {}