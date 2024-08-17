resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-aca-acr-abac-${var.prefix}"
  location = "swedencentral"
}
