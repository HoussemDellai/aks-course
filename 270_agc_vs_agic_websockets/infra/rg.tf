resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-agc-agic-${var.prefix}"
  location = "swedencentral" # "westcentralus" # 

  tags = {
    SecurityControl = "Ignore"
  }
}
