resource "azurerm_resource_group" "rg-hub" {
  name     = "rg-hub-vpn-p2s-${var.prefix}"
  location = "swedencentral"
}