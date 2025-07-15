resource "azurerm_virtual_network" "vnet-spoke" {
  name                = "vnet-spoke"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "snet-aks-lb" {
  name                 = "snet-aks-lb"
  resource_group_name  = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "snet-appgateway" {
  name                 = "snet-appgateway"
  resource_group_name  = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "snet-vm" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  address_prefixes     = ["10.10.3.0/24"]
}