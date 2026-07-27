resource "azurerm_storage_account" "sa" {
  name                     = "storaks${var.prefix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "content"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "blob" {
  name                   = "storage_account.tf"
  storage_container_id = azurerm_storage_container.container.id
  type                   = "Block"
  source                 = "storage_account.tf"
}
