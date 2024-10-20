resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-${var.prefix}"
  location = var.location
}

resource "azurerm_resource_group" "rg-backup" {
  name     = "rg-aks-backup-${var.prefix}"
  location = var.location
}

resource "azurerm_resource_group" "rg-2" {
  name     = "rg-aks-2-${var.prefix}"
  location = var.location
}