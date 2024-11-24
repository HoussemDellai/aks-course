resource "azurerm_virtual_network" "vnet-spoke" {
  name                = "vnet-spoke"
  resource_group_name = azurerm_resource_group.rg-spoke.name
  location            = azurerm_resource_group.rg-spoke.location
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "subnet-aks"
  resource_group_name  = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  address_prefixes     = ["10.2.0.0/24"]
}