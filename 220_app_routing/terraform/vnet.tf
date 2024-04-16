resource "azurerm_virtual_network" "vnet-aks" {
  name                = "vnet-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.10.0.0/16"]
  dns_servers         = null
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_virtual_network.vnet-aks.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-aks.name
  address_prefixes     = ["10.10.0.0/24"]
}