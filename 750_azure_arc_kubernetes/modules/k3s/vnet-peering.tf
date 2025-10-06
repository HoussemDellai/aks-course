resource "azurerm_virtual_network_peering" "vnet-peering-hub-to-spoke" {
  name                         = "vnet-peering-hub-to-${azurerm_virtual_network.vnet.name}"
  virtual_network_name         = var.vnet_hub_name
  resource_group_name          = var.vnet_hub_rg
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "vnet-peering-spoke-to-hub" {
  name                         = "vnet-peering-${azurerm_virtual_network.vnet.name}-to-hub"
  virtual_network_name         = azurerm_virtual_network.vnet.name
  resource_group_name          = azurerm_virtual_network.vnet.resource_group_name
  remote_virtual_network_id    = var.vnet_hub_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}