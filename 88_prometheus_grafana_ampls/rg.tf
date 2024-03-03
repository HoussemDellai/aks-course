resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-monitoring-${var.prefix}"
  location = var.location
}

resource "azurerm_resource_group" "rg-jumpbox" {
  name     = "rg-jumpbox-${var.prefix}"
  location = var.location
}

