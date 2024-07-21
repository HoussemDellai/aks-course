resource "azurerm_virtual_network" "vnet-spoke" {
  name                = "vnet-spoke-${var.location}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = ["10.10.0.0/16"]
  dns_servers         = null
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke.name
  address_prefixes     = ["10.10.0.0/24"]
}