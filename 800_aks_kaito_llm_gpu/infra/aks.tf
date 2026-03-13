resource "azurerm_kubernetes_cluster" "aks" {
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  name                      = "aks-cluster"
  dns_prefix                = "aks-${random_integer.example.result}"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name       = "systemnp"
    node_count = 2
    vm_size    = "Standard_D2ads_v6"

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
