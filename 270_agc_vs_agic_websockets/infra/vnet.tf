resource "azurerm_virtual_network" "vnet_spoke_aks" {
  name                = "vnet-spoke-aks-simple"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "snet_aks" {
  name                 = "snet-aks"
  virtual_network_name = azurerm_virtual_network.vnet_spoke_aks.name
  resource_group_name  = azurerm_virtual_network.vnet_spoke_aks.resource_group_name
  address_prefixes     = ["10.1.1.0/24"]
}

# snet-apiserver
resource "azurerm_subnet" "snet_aks_apiserver" {
  # count                = var.enable_apiserver_vnet_integration ? 1 : 0
  name                 = "snet-aks-apiserver"
  virtual_network_name = azurerm_virtual_network.vnet_spoke_aks.name
  resource_group_name  = azurerm_virtual_network.vnet_spoke_aks.resource_group_name
  address_prefixes     = ["10.1.2.0/28"]

  delegation {
    name = "aks-apiserver-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# # snet_appgateway
# resource "azurerm_subnet" "snet_appgw" {
#   name                 = "snet-appgw"
#   virtual_network_name = azurerm_virtual_network.vnet_spoke_aks.name
#   resource_group_name  = azurerm_virtual_network.vnet_spoke_aks.resource_group_name
#   address_prefixes     = ["10.1.3.0/24"]

#   delegation {
#     name = "delegation"
#     service_delegation {
#       name    = "Microsoft.Network/applicationGateways"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
#     }
#   }
# }

resource "azurerm_subnet" "snet_appgw_managed" {
  name                 = "snet-appgw-managed"
  virtual_network_name = azurerm_virtual_network.vnet_spoke_aks.name
  resource_group_name  = azurerm_virtual_network.vnet_spoke_aks.resource_group_name
  address_prefixes     = ["10.1.4.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Network/applicationGateways"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "snet_agc" {
  name                 = "snet-agc"
  resource_group_name  = azurerm_virtual_network.vnet_spoke_aks.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_spoke_aks.name
  address_prefixes     = ["10.1.5.0/24"]

  delegation {
    name = "delegation-agc"

    service_delegation {
      name    = "Microsoft.ServiceNetworking/trafficControllers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
