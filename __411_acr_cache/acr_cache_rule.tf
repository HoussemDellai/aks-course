# resource "azurerm_container_registry_cache_rule" "cache_rule" {
#   name                  = "cacherule"
#   container_registry_id = azurerm_container_registry.acr.id
#   target_repo           = "target"
#   source_repo           = "docker.io/hello-world"
#   credential_set_id     = "${azurerm_container_registry.acr.id}/credentialSets/example"
# }