resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-monitoring-ampls-${var.prefix}"
  location = var.location
}

resource "azurerm_resource_group" "rg-jumpbox" {
  name     = "rg-vm-jumpbox-${var.prefix}"
  location = var.location
}