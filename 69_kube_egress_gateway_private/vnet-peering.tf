resource "azurerm_virtual_network_peering" "peering-hub-to-spoke" {
  name                         = "hub-to-spoke"
  resource_group_name          = azurerm_virtual_network.vnet-hub.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "peering-spoke-to-hub" {
  name                         = "spoke-to-hub"
  resource_group_name          = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet-spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}
