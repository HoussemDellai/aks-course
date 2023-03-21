resource "azurerm_resource_group" "rg_backup_vault" {
  name     = "rg-backup-vault"
  location = "West Europe"
}

resource "azurerm_data_protection_backup_vault" "vault" {
  name                = "backup-vault"
  resource_group_name = azurerm_resource_group.rg_backup_vault.name
  location            = azurerm_resource_group.rg_backup_vault.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"
}

# backup instance for AKS

# backup policy for AKS
