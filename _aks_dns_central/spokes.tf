module "spoke-aks-001" {
  source = "./modules/spoke"

  prefix        = "001"
  location      = var.location
  address_space = ["10.1.0.0/16"]

  vnet_hub_name           = azurerm_virtual_network.vnet-hub.name
  vnet_hub_resource_group = azurerm_virtual_network.vnet-hub.resource_group_name
  vnet_hub_id             = azurerm_virtual_network.vnet-hub.id
}

module "spoke-aks-002" {
  source = "./modules/spoke"

  prefix        = "002"
  location      = var.location
  address_space = ["10.2.0.0/16"]

  vnet_hub_name           = azurerm_virtual_network.vnet-hub.name
  vnet_hub_resource_group = azurerm_virtual_network.vnet-hub.resource_group_name
  vnet_hub_id             = azurerm_virtual_network.vnet-hub.id
}
