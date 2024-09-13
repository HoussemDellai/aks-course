resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-cluster"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "aks"
  kubernetes_version      = "1.30.3"
  private_cluster_enabled = true
  private_dns_zone_id     = "System"

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "loadBalancer"
  }

  default_node_pool {
    name           = "systemnp"
    node_count     = 2
    vm_size        = "Standard_B2als_v2"
    os_sku         = "AzureLinux"
    vnet_subnet_id = azurerm_subnet.snet-aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}
