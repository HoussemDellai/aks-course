resource "azurerm_virtual_network" "vnet-spoke" {
  name                = "vnet-spoke"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  resource_group_name  = azurerm_virtual_network.vnet-spoke.resource_group_name
  address_prefixes     = ["10.10.0.0/24"]
}

# hub to spoke peering
resource "azurerm_virtual_network_peering" "hub-to-spoke" {
  name                         = "hub-to-spoke"
  resource_group_name          = azurerm_virtual_network.vnet-hub.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# spoke to hub peering
resource "azurerm_virtual_network_peering" "spoke-to-hub" {
  name                         = "spoke-to-hub"
  resource_group_name          = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet-spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}