resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-cluster"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "aks"
  kubernetes_version      = "1.30.3"
  private_cluster_enabled = false

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  default_node_pool {
    name       = "mainpool"
    node_count = 2
    vm_size    = "Standard_B2als_v2"
    os_sku     = "AzureLinux"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_aks.id]
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}

# managed identity for the AKS cluster

resource "azurerm_user_assigned_identity" "identity_aks" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "identity-aks"
}
