resource "azurerm_resource_group" "rg" {
  name     = "rg-arc-k8s-${var.location}-${var.prefix}"
  location = var.location
}