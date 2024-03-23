resource "azurerm_virtual_network" "vnet-proxy" {
  name                = "vnet-proxy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = null
}

resource "azurerm_subnet" "snet-proxy" {
  name                 = "snet-proxy"
  resource_group_name  = azurerm_virtual_network.vnet-proxy.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-proxy.name
  address_prefixes     = ["10.0.0.0/24"]
}