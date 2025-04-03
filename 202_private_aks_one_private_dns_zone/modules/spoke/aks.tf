resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg-spoke.location
  resource_group_name = azurerm_resource_group.rg-spoke.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.29.2"

  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  private_dns_zone_id                 = var.private_dns_zone_id
  # (Optional) Either the ID of Private DNS Zone which should be delegated to this Cluster, 
  # System to have AKS manage this 
  # or None. 
  # In case of None you will need to bring your own DNS server and set up resolving, 
  # otherwise, the cluster will have issues after provisioning. 

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "loadBalancer"
  }

  default_node_pool {
    name                  = "systemnp"
    node_count            = 2
    vm_size               = "Standard_B2als_v2"
    os_sku                = "AzureLinux"
    vnet_subnet_id        = azurerm_subnet.snet-spoke-aks.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity-aks.id]
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }

  depends_on = [
    azurerm_role_assignment.private-dns-zone-contributor,
    azurerm_role_assignment.network-contributor
  ]
}