
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-blob-adls-wi-${var.prefix}"
  location = "italynorth" # "swedencentral"

  tags = {
    SecurityControl = "Ignore"
  }
}