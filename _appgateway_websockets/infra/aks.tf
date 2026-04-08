
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-cluster"
  kubernetes_version        = null # var.kubernetes_version
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  dns_prefix                = "aks"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name            = "systempool"
    vm_size         = "standard_d2ads_v6"
    node_count      = 3
    zones           = [1, 2, 3] # []
    os_sku          = "Ubuntu2404"
    os_disk_type    = "Ephemeral" #"Managed" #
    os_disk_size_gb = 32
    vnet_subnet_id  = azurerm_subnet.snet_aks.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_aks.id]
  }

  network_profile {
    network_plugin      = "azure" # var.aks_network_plugin # "kubenet", "azure", "none"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium" # azure and cilium
    network_policy      = "cilium" # calico, azure and cilium
  }

  api_server_access_profile {
    virtual_network_integration_enabled = true
    subnet_id                           = azurerm_subnet.snet_aks_apiserver.id
  }

  ingress_application_gateway {
    # gateway_name = "appgw-aks-agic-swc"
    # subnet_cidr  = "10.1.3.0/24"
    # gateway_id = azurerm_application_gateway.appgw.id
    subnet_id = azurerm_subnet.snet_appgw_managed.id
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}
