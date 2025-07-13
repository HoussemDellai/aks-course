resource "azurerm_virtual_network_peering" "vnet-peering-hub-to-spoke" {
  name                         = "vnet-peering-hub-to-spoke"
  virtual_network_name         = azurerm_virtual_network.vnet-hub.name
  resource_group_name          = azurerm_virtual_network.vnet-hub.resource_group_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet-peering-spoke-to-hub" {
  name                         = "vnet-peering-spoke-to-hub"
  virtual_network_name         = azurerm_virtual_network.vnet-spoke.name
  resource_group_name          = azurerm_virtual_network.vnet-spoke.resource_group_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}