resource "azurerm_virtual_network_peering" "peering-hub-to-spoke" {
  for_each = tomap(var.spokes)

  name                         = "hub-to-spoke-${each.key}"
  resource_group_name          = azurerm_resource_group.rg-hub.name
  virtual_network_name         = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-spoke[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "peering-spoke-to-hub" {
  for_each = tomap(var.spokes)

  name                         = "spoke-${each.key}-to-hub"
  resource_group_name          = azurerm_resource_group.rg-spoke[each.key].name
  virtual_network_name         = azurerm_virtual_network.vnet-spoke[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}