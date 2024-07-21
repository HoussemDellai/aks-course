module "aks-region1" {
  source              = "../modules/aks"
  location            = "swedencentral"
  resource_group_name = azurerm_resource_group.rg.name
}

module "aks-region2" {
  source              = "../modules/aks"
  location            = "francecentral"
  resource_group_name = azurerm_resource_group.rg.name
}
