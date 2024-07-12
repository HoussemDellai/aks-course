resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-apim-${var.prefix}"
  location = var.location
}