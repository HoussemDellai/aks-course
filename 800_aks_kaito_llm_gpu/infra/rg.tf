
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-kaito-${var.prefix}"
  location = "swedencentral"
}