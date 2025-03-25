resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-cluster"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "aks"
  kubernetes_version      = "1.32.0"
  private_cluster_enabled = false
  # private_dns_zone_id     = "System"

  network_profile {
    network_plugin = "azure"
    outbound_type  = "loadBalancer"
    # network_plugin_mode = "overlay"
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

  web_app_routing {
    dns_zone_ids = []
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}
