resource "azurerm_resource_group" "rg" {
  name     = "rg-private-aks-bastion-${var.prefix}"
  location = var.location
}