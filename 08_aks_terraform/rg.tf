resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-cluster-${var.prefix}"
  location = var.location
}
