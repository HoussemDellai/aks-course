resource "azurerm_virtual_network_peering" "aks-to-proxy" {
  name                         = "aks-to-proxy"
  resource_group_name          = azurerm_virtual_network.vnet-aks.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet-aks.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-proxy.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "proxy-to-aks" {
  name                         = "proxy-to-aks"
  resource_group_name          = azurerm_virtual_network.vnet-proxy.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet-proxy.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-aks.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}