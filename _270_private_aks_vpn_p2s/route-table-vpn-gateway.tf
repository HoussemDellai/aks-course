resource "azurerm_route_table" "route-table-vpn-gateway" {
  name                          = "route-table-vpn-gateway"
  location                      = azurerm_resource_group.rg-hub.location
  resource_group_name           = azurerm_resource_group.rg-hub.name
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "route-to-firewall-vpn-gateway" {
  name                   = "route-to-firewall-vpn-gateway"
  resource_group_name    = azurerm_resource_group.rg-hub.name
  route_table_name       = azurerm_route_table.route-table-vpn-gateway.name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration.0.private_ip_address
}

resource "azurerm_subnet_route_table_association" "association-route-table-snet-vpn-gateway" {
  subnet_id      = azurerm_subnet.snet-gateway.id
  route_table_id = azurerm_route_table.route-table-vpn-gateway.id
}