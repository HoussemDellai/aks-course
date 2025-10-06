resource "azurerm_route_table" "route-table-to-nva" {
  name                          = "route-table-to-nva"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "route-to-nva" {
  name                   = "route-to-nva"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.route-table-to-nva.name
  address_prefix         = "0.0.0.0/0" # azurerm_virtual_network.vnet-spoke2.address_space[0] # "10.2.0.0/16" # 
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

resource "azurerm_subnet_route_table_association" "association_route_table_subnet" {
  subnet_id      = azurerm_subnet.snet_vm.id
  route_table_id = azurerm_route_table.route-table-to-nva.id
}
