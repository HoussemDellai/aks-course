resource "azurerm_kubernetes_cluster" "aks" {
  for_each = tomap(var.spokes)

  name                = "aks-cluster"
  location            = azurerm_resource_group.rg-spoke[each.key].location
  resource_group_name = azurerm_resource_group.rg-spoke[each.key].name
  dns_prefix          = "aks"
  kubernetes_version  = "1.29.2"

  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  private_dns_zone_id                 = azurerm_private_dns_zone.private_dns_zone[each.key].id
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
    vnet_subnet_id        = azurerm_subnet.snet-spoke-aks[each.key].id
    enable_node_public_ip = false
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity-aks[each.key].id]
  }
}

# resource "azurerm_kubernetes_cluster_node_pool" "nodepool" {
#   for_each = { for cluster in var.aks : cluster.cluster_name => cluster }

#   name                  = "usernp"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[each.key].id
#   vm_size               = "Standard_B2als_v2"
#   node_count            = each.value.node_count
#   priority              = "Spot"
# }
