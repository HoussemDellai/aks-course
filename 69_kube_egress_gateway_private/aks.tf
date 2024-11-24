resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster-swc"
  location            = azurerm_resource_group.rg-spoke.location
  resource_group_name = azurerm_resource_group.rg-spoke.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.30.5"

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "userDefinedRouting"
  }

  default_node_pool {
    name                        = "systempool"
    temporary_name_for_rotation = "syspool"
    node_count                  = 3
    vm_size                     = "standard_b2als_v2"
    zones                       = [1, 2, 3]
    vnet_subnet_id              = azurerm_subnet.snet-aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }

  depends_on = [
    azurerm_subnet_route_table_association.association_route_table_subnet_spoke,
    azurerm_route.route-to-nva-spoke,
    azurerm_route.route-firewall-ip
  ]
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [azurerm_kubernetes_cluster.aks.id]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}
