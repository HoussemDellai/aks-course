resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-service-connector-${var.prefix}"
  location = "swedencentral"
}
