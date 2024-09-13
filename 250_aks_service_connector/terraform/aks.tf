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

  kubelet_identity {
    user_assigned_identity_id = azurerm_user_assigned_identity.identity_aks_kubelet.id
    client_id                 = azurerm_user_assigned_identity.identity_aks_kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.identity_aks_kubelet.principal_id
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

  depends_on = [ azurerm_role_assignment.role_managed_identity_operator ]
}

resource "azurerm_user_assigned_identity" "identity_aks" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "identity-aks"
}

resource "azurerm_user_assigned_identity" "identity_aks_kubelet" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "identity-aks-kubelet"
}

# The cluster using user-assigned managed identity must be granted 'Managed Identity Operator' role to assign kubelet identity.
resource "azurerm_role_assignment" "role_managed_identity_operator" {
  scope                = azurerm_user_assigned_identity.identity_aks_kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.identity_aks.principal_id
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}
