resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-spoke-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["${var.vnet_address_space}"]
}

resource "azurerm_subnet" "snet_vm" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_virtual_network_peering" "vnet-peering-hub-to-spoke" {
  name                         = "vnet-peering-hub-to-spoke"
  virtual_network_name         = var.vnet_hub_name
  resource_group_name          = var.vnet_hub_rg
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "vnet-peering-spoke-to-hub" {
  name                         = "vnet-peering-spoke-to-hub"
  virtual_network_name         = azurerm_virtual_network.vnet.name
  resource_group_name          = azurerm_virtual_network.vnet.resource_group_name
  remote_virtual_network_id    = var.vnet_hub_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}