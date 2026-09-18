terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.66.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id                 = "dcef7009-6b94-4382-afdc-17eb160d709a"
  resource_provider_registrations = "core"
  resource_providers_to_register = [
    "Microsoft.Kubernetes",
    "Microsoft.KubernetesConfiguration",
    "Microsoft.ExtendedLocation",
  ]
}

data "azurerm_client_config" "current" {}