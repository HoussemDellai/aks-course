resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-cluster"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "aks"
  kubernetes_version      = "1.33.1"
  private_cluster_enabled = false

  network_profile {
    network_plugin      = "azure" # var.aks_network_plugin # "kubenet", "azure", "none"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"       # azure and cilium
    network_policy      = "cilium"       # calico, azure and cilium
    outbound_type       = "loadBalancer" # "managedNATGateway" "userAssignedNATGateway" "loadBalancer" "none" "block"
    load_balancer_sku   = "standard"     # "basic"
  }

  default_node_pool {
    name            = "systemnp"
    node_count      = 2
    vm_size         = "Standard_D2ads_v6"
    os_sku          = "AzureLinux"
    os_disk_size_gb = 40
    os_disk_type    = "Ephemeral" #"Managed" #
    scale_down_mode = "Delete"
    vnet_subnet_id  = azurerm_subnet.snet-aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  web_app_routing {
    dns_zone_ids = []
    # default_nginx_controller = "Internal"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}

# Required to create internal Load Balancer for Nginx Ingress Controller
resource "azurerm_role_assignment" "network-contributor" {
  scope                = azurerm_subnet.snet-aks-lb.id # azurerm_virtual_network.vnet-spoke.id # 
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}
