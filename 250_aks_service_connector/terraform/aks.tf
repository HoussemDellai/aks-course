resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-cluster"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  dns_prefix                = "aks"
  kubernetes_version        = "1.30.5"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  default_node_pool {
    name                        = "mainpool"
    node_count                  = 2
    vm_size                     = "standard_d2pds_v6"
    os_sku                      = "Ubuntu"
    vnet_subnet_id              = azurerm_subnet.snet-aks.id
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

resource "azurerm_role_assignment" "aks-kubelet-identity-acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  # skip_service_principal_aad_check = true
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}
