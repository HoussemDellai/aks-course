resource "azurerm_container_registry" "acr" {
  name                          = "acr1abac"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = false
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  network_rule_bypass_option    = "AzureServices"

  provisioner "local-exec" {
    # interpreter = ["PowerShell", "-Command"]
    command = "az acr import --name ${azurerm_container_registry.acr.login_server} --source docker.io/library/nginx:latest --image nginx:latest"
    # command = "az acr import --name ${azurerm_container_registry.acr.login_server} --source docker.io/library/hello-world:latest --image hello-world:latest"
    when    = create
  }
}

resource "azurerm_container_registry_cache_rule" "cache_rule" {
  name                  = "cacherule"
  container_registry_id = azurerm_container_registry.acr.id
  target_repo           = "app1/nginx"
  source_repo           = "docker.io/library/nginx:latest" # "docker.io/hello-world"
#   credential_set_id     = "${azurerm_container_registry.acr.id}/credentialSets/example"
}