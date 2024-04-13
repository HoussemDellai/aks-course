resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg-spoke.location
  resource_group_name = azurerm_resource_group.rg-spoke.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.29.2"

  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true
  private_dns_zone_id                 = "None" # azurerm_private_dns_zone.private_dns_zone.id
  # (Optional) Either the ID of Private DNS Zone which should be delegated to this Cluster, 
  # System to have AKS manage this 
  # or None. 
  # In case of None you will need to bring your own DNS server and set up resolving, 
  # otherwise, the cluster will have issues after provisioning. 

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  default_node_pool {
    name                  = "systemnp"
    node_count            = 2
    vm_size               = "Standard_B2als_v2"
    os_sku                = "AzureLinux"
    vnet_subnet_id        = azurerm_subnet.snet-spoke-aks.id
    enable_node_public_ip = false
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
