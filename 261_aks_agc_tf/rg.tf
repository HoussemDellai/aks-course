resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-agc-${var.prefix}-poc"
  location = var.location
}