resource "azurerm_virtual_network" "vnet_aks" {
  name                = "vnet-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["100.64.0.0/10"]
}

resource "azurerm_subnet" "snet_aks" {
  name                            = "snet-aks"
  resource_group_name             = azurerm_virtual_network.vnet_aks.resource_group_name
  virtual_network_name            = azurerm_virtual_network.vnet_aks.name
  address_prefixes                = ["100.64.1.0/24"]
  default_outbound_access_enabled = false
}
