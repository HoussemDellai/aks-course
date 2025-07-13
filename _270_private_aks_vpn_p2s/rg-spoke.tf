resource "azurerm_resource_group" "rg-spoke" {
  name     = "rg-spoke-private-aks-${var.prefix}"
  location = "swedencentral"
}