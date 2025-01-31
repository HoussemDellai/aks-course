terraform {

  required_version = ">= 1.2.8"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.16.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.2.0" # 1.12.1
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy               = true
      purge_soft_deleted_secrets_on_destroy      = true
      purge_soft_deleted_keys_on_destroy         = true
      purge_soft_deleted_certificates_on_destroy = true
      recover_soft_deleted_key_vaults            = true
      recover_soft_deleted_secrets               = true
      recover_soft_deleted_certificates          = true
      recover_soft_deleted_keys                  = true
    }
  }
}
