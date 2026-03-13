
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-kaito-swc-9${var.prefix}"
  location = "swedencentral"
}