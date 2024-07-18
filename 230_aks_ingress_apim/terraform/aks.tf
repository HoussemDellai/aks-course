resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-cluster"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "aks"
  kubernetes_version      = "1.30.0"
  private_cluster_enabled = false

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  default_node_pool {
    name                  = "mainpool"
    node_count            = 3
    vm_size               = "Standard_B2als_v2"
    os_sku                = "AzureLinux"
    vnet_subnet_id        = azurerm_subnet.snet-aks.id
    enable_node_public_ip = false
  }

  identity {
    type = "SystemAssigned"
  }

  web_app_routing {
    dns_zone_ids = null
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}

# Required to create internal Load Balancer for Nginx Ingress Controller
resource "azurerm_role_assignment" "network-contributor" {
  scope                = azurerm_subnet.snet-aks.id
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
