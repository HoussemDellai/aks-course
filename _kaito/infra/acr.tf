resource "azurerm_container_registry" "acr" {
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  name                   = "acr4kaito2${random_integer.example.result}"
  sku                    = "Standard"
  admin_enabled          = false
  anonymous_pull_enabled = false
}

resource "azurerm_container_registry_scope_map" "scopemap" {
  name                    = "default"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.rg.name

  actions = [
    "repositories/${var.registry_repository_name}/content/read",
    "repositories/${var.registry_repository_name}/content/write"
  ]
}

resource "azurerm_container_registry_token" "token" {
  name                    = "default"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.rg.name
  scope_map_id            = azurerm_container_registry_scope_map.scopemap.id
}

resource "azurerm_container_registry_token_password" "password" {
  container_registry_token_id = azurerm_container_registry_token.token.id

  password1 {
    expiry = timeadd(timestamp(), "168h") # 7 days
  }
}