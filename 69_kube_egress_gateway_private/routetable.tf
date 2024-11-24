resource "azurerm_route_table" "route-table-to-nva-spoke" {
  name                          = "route-table-to-nva-spoke"
  location                      = azurerm_resource_group.rg-spoke.location
  resource_group_name           = azurerm_resource_group.rg-spoke.name
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "route-to-nva-spoke" {
  name                   = "route-to-nva-spoke"
  resource_group_name    = azurerm_route_table.route-table-to-nva-spoke.resource_group_name
  route_table_name       = azurerm_route_table.route-table-to-nva-spoke.name
  address_prefix         = "0.0.0.0/0" # azurerm_virtual_network.vnet-spoke2.address_space[0] # "10.2.0.0/16" # 
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration.0.private_ip_address # module.vm-hub-nva.vm_private_ip
}

# az network route-table route create --resource-group $RG --name $FWROUTE_NAME_INTERNET --route-table-name $FWROUTE_TABLE_NAME --address-prefix $FWPUBLIC_IP/32 --next-hop-type Internet
resource "azurerm_route" "route-firewall-ip" {
  name                   = "route-firewall-ip"
  resource_group_name    = azurerm_route_table.route-table-to-nva-spoke.resource_group_name
  route_table_name       = azurerm_route_table.route-table-to-nva-spoke.name
  address_prefix         = "${azurerm_public_ip.pip-firewall.ip_address}/32"
  next_hop_type          = "Internet"
}

resource "azurerm_subnet_route_table_association" "association_route_table_subnet_spoke" {
  subnet_id      = azurerm_subnet.snet-aks.id
  route_table_id = azurerm_route_table.route-table-to-nva-spoke.id
}