resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-proxy-${var.prefix}"
  location = "swedencentral"
}