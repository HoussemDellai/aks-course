resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-agc-agic-${var.prefix}"
  location = var.location

  tags = {
    SecurityControl = "Ignore"
  }
}
