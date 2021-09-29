provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
<<<<<<< HEAD
      version = "2.74.0"
=======
      version = "2.75.0"
>>>>>>> d0ce4e29bc244884aebc08da2a35438218b21bdb
    }
  }
}
