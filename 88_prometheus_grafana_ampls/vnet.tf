resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "snet-pe" {
  name                 = "snet-pe"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
  address_prefixes     = ["10.10.1.0/24"]

  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "snet-bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
  address_prefixes     = ["10.10.2.0/24"]
}
