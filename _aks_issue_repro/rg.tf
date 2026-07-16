resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-issue-repro"
  location = "francecentral"
}