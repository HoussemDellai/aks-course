resource "azurerm_virtual_network" "vnet-spoke" {
  name                = "vnet-spoke"
  resource_group_name = azurerm_resource_group.rg-spoke.name
  location            = azurerm_resource_group.rg-spoke.location
  address_space       = each.value
  dns_servers         = null
}

resource "azurerm_subnet" "snet-spoke-aks" {
  name                 = "snet-spoke-aks"
  resource_group_name  = azurerm_virtual_network.vnet-spoke.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  address_prefixes     = each.value # cidrsubnet(each.value[0], 4, 2)
}
