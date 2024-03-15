resource "azurerm_data_protection_backup_vault" "backup-vault" {
  name                = "backup-vault"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "vault_msi_read_on_cluster" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_msi_read_on_snap_rg" {
  scope                = azurerm_resource_group.rg-backup.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}