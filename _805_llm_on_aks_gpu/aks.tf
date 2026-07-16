resource "azurerm_kubernetes_cluster" "aks" {
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  name                      = "aks-cluster"
  dns_prefix                = "aks"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure" # var.aks_network_plugin # "kubenet", "azure", "none"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium" # azure and cilium
    network_policy      = "cilium" # calico, azure and cilium
  }

  default_node_pool {
    name                        = "systemnp"
    temporary_name_for_rotation = "systemnptmp"
    node_count                  = 2
    vm_size                     = "Standard_D2ads_v6"
    os_disk_size_gb             = 64
    os_disk_type                = "Ephemeral" # "Managed"
    ultra_ssd_enabled           = false
    os_sku                      = "Ubuntu" # Ubuntu, AzureLinux, Windows2019, Windows2022

    upgrade_settings {
      drain_timeout_in_minutes      = 10
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 1
      undrainable_node_behavior     = "Cordon" # "Schedule"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
