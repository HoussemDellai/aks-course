resource "azurerm_resource_group" "rg" {
  name     = "rg-akscluster-${var.prefix}"
  location = var.location
}

resource "azurerm_resource_group" "rg-backup" {
  name     = "rg-aks-backup-${var.prefix}"
  location = var.location
}