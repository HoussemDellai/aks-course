
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-gpu-llm-${var.prefix}"
  location = "italynorth" # "swedencentral"
}