resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-apim-gateway-${var.prefix}"
  location = var.location
}