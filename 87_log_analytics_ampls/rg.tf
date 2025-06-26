resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-ampls-loganalytics-${var.prefix}"
  location = "swedencentral"
}

resource "azurerm_resource_group" "rg-jumpbox" {
  name     = "rg-vm-jumpbox-${var.prefix}"
  location = "swedencentral"
}

