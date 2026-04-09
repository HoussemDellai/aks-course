resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-agc-agic-${var.prefix}"
  location = "westcentralus" # "swedencentral"

  tags = {
    SecurityControl = "Ignore"
  }
}
