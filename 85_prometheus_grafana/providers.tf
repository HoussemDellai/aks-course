terraform {

  required_version = ">= 1.11"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.44.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.11.1"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "time" {
  # Configuration options
}
