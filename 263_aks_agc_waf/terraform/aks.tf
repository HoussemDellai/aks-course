resource "azurerm_kubernetes_cluster" "aks" {
  name = "aks-agc-demo"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = "aks"
  default_node_pool { name = "system" node_count = 1 vm_size = "Standard_DS2_v2" }
  identity { type = "SystemAssigned" }
}
