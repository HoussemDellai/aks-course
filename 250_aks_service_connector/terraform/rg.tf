resource "azurerm_resource_group" "rg" {
  name     = "rg-service-connector-${var.prefix}"
  location = "swedencentral"
}
