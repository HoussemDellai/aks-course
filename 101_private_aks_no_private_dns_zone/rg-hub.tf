resource "azurerm_resource_group" "rg-hub" {
  name     = "rg-hub-${var.prefix}"
  location = var.location
}