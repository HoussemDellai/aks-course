
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-kaito-llm-${var.prefix}"
  location = "swedencentral"
}