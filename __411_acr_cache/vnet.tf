resource "azurerm_virtual_network" "vnet-aks" {
  name                = "vnet-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.224.0.0/22"]
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  virtual_network_name = azurerm_virtual_network.vnet-aks.name
  resource_group_name  = azurerm_virtual_network.vnet-aks.resource_group_name
  address_prefixes     = ["10.224.0.0/24"]
}

resource "azurerm_subnet" "snet-acr" {
  name                 = "snet-acr"
  virtual_network_name = azurerm_virtual_network.vnet-aks.name
  resource_group_name  = azurerm_virtual_network.vnet-aks.resource_group_name
  address_prefixes     = ["10.224.1.0/24"]
}

resource "azurerm_subnet" "snet-bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet-aks.name
  resource_group_name  = azurerm_virtual_network.vnet-aks.resource_group_name
  address_prefixes     = ["10.224.2.0/24"]
}

