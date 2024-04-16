resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-approuting-${var.prefix}"
  location = var.location
}