resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-agc-${var.prefix}-dev"
  location = var.location
}