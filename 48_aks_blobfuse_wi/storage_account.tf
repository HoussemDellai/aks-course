resource "azurerm_storage_account" "sa" {
  name                          = "stor4aks${var.prefix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  account_tier                  = "Premium" # "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "BlockBlobStorage" # BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Defaults to StorageV2, BlobFuse stores files as block blobs.
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  # is_hns_enabled                = true

  tags = {
    SecurityControl = "Ignore"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "content"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# resource "azurerm_storage_blob" "blob" {
#   name                 = "storage_account.tf"
#   storage_container_id = azurerm_storage_container.container.id
#   type                 = "Page" # "Block" # "Append" # 
#   source               = "storage_account.tf"
# }

# resource "azurerm_storage_data_lake_gen2_filesystem" "example" {
#   name               = "example"
#   storage_account_id = azurerm_storage_account.sa.id
# }

# resource "azurerm_storage_data_lake_gen2_path" "example" {
#   path               = "example"
#   filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.example.name
#   storage_account_id = azurerm_storage_account.sa.id
#   resource           = "directory"
# }

resource "azurerm_role_assignment" "storage_account_contributor" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Storage Account Contributor"
  scope                = azurerm_storage_account.sa.id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.sa.id
}

data "azurerm_client_config" "current" {}
