resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-create-pods-${var.prefix}"
  location = var.location
}