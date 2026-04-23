resource "azurerm_storage_account" "storage" {
  name                             = "storage4aks4backup${var.prefix}"
  resource_group_name              = azurerm_resource_group.rg_backup.name
  location                         = azurerm_resource_group.rg_backup.location
  account_tier                     = "Standard"
  account_replication_type         = "ZRS" # "GRS"
  shared_access_key_enabled        = true
  cross_tenant_replication_enabled = true

  tags = {
    SecurityControl = "Ignore"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "backup-container"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
