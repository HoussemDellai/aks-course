resource "azurerm_kubernetes_cluster_node_pool" "nc24ads_a100_v4" {
  name                  = "nc24adsa100"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  mode                  = "User"
  vm_size               = "Standard_NC24ads_A100_v4"
  node_count            = 1
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 3
  gpu_driver            = "None" # "Install" or "None"
  os_type               = "Linux"
  zones                 = []
  priority              = "Spot"
  eviction_policy       = "Delete"
  #   gpu_instance = "MIG1g"

  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "apps"                                  = "phi-4"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
  ]

  tags = {
    EnableManagedGPUExperience = true # enables managed GPU experience for the node pool, which includes automatic installation and management of GPU drivers and monitoring of GPU health and performance
  }
}
