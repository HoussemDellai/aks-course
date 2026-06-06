resource "azurerm_kubernetes_cluster" "aks" {
  for_each = { for cluster in var.aks : cluster.cluster_name => cluster }

  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"
  kubernetes_version  = each.value.version

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    outbound_type       = "loadBalancer"
  }

  default_node_pool {
    name       = "systemnp"
    node_count = 2
    vm_size    = "Standard_D2ads_v6"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "nodepool" {
  for_each = { for cluster in var.aks : cluster.cluster_name => cluster }

  name                  = "usernp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[each.key].id
  vm_size               = "Standard_D2ads_v6"
  node_count            = each.value.node_count
  priority              = "Spot"
}
