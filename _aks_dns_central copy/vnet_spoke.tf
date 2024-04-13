resource "azurerm_virtual_network" "vnet-spoke" {
  for_each = tomap(var.spokes)

  name                = "vnet-spoke"
  resource_group_name = azurerm_resource_group.rg-spoke[each.key].name
  location            = azurerm_resource_group.rg-spoke[each.key].location
  address_space       = each.value
  dns_servers         = null
}

resource "azurerm_subnet" "snet-spoke-aks" {
  for_each = tomap(var.spokes)
  
  name                 = "snet-spoke-aks"
  resource_group_name  = azurerm_virtual_network.vnet-spoke[each.key].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-spoke[each.key].name
  address_prefixes     = each.value # cidrsubnet(each.value[0], 4, 2)
}
