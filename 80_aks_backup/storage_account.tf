resource "azurerm_resource_group" "rg_backup_storage" {
  name     = "rg-backup-storage-aks"
  location = "West Europe"
}

resource "azurerm_storage_account" "sa_backup_aks" {
  name                     = "storage4aks1backup13579"
  resource_group_name      = azurerm_resource_group.rg_backup_storage.name
  location                 = azurerm_resource_group.rg_backup_storage.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container_backup_aks" {
  name                  = "aks-backup"
  storage_account_name  = azurerm_storage_account.sa_backup_aks.name
  container_access_type = "private"
}