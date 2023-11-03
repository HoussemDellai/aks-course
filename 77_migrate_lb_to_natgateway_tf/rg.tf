resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-cluster-dev"
  location = "westeurope"
}