resource "azurerm_container_registry" "acr" {
  name                          = "acr4aks${var.prefix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = false
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  network_rule_bypass_option    = "AzureServices"
}

# resource "terraform_data" "acr_build_container" {
#   triggers_replace = [
#     azurerm_container_registry.acr.id
#   ]

#   provisioner "local-exec" {
#     command = "az acr build -r ${azurerm_container_registry.acr.name} -t app-python:1.0.0 ../app-python"
#   }
# }