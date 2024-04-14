resource "azurerm_virtual_network_peering" "peering-hub-to-spoke" {
  name                         = "hub-to-spoke-${var.prefix}"
  resource_group_name          = var.vnet_hub_resource_group
  virtual_network_name         = var.vnet_hub_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "peering-spoke-to-hub" {
  name                         = "spoke-${var.prefix}-to-hub"
  resource_group_name          = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet-spoke.name
  remote_virtual_network_id    = var.vnet_hub_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}