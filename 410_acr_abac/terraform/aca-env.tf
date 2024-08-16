resource "azurerm_container_app_environment" "aca_environment" {
  name                = "aca-environment"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}