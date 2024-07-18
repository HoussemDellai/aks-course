resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-frontdoor-${var.prefix}"
  location = var.location
}