resource "azurerm_kubernetes_cluster" "aks" {
  name                                = "aks-cluster"
  location                            = azurerm_resource_group.rg.location
  resource_group_name                 = azurerm_resource_group.rg.name
  dns_prefix                          = "jlephayaks"
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  role_based_access_control_enabled   = true
  local_account_disabled              = true
  workload_identity_enabled           = true
  oidc_issuer_enabled                 = true

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    admin_group_object_ids = [azuread_group.aks_cluster_admins.object_id]
  }

  default_node_pool {
    name                 = "nodepool1"
    vm_size              = "Standard_DS3_v2"
    vnet_subnet_id       = azurerm_subnet.snet_aks.id
    zones                = ["1", "2"] # --zones 1 2
    auto_scaling_enabled = true       # --enable-cluster-autoscaler
    node_count           = 2          # --node-count 4
    min_count            = 2          # --min-count 4
    max_count            = 2          # --max-count 4
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_aks.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.identity_kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.identity_kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.identity_kubelet.id
  }

  network_profile {
    network_plugin      = "azure"                  # --network-plugin azure
    network_plugin_mode = "overlay"                # --network-plugin-mode overlay
    network_data_plane  = "cilium"                 # --network-dataplane cilium
    network_policy      = "cilium"                 # required when data plane is cilium
    outbound_type       = "userAssignedNATGateway" # --outbound-type userAssignedNATGateway
    pod_cidr            = "172.16.0.0/16"          # --pod-cidr
    service_cidr        = "172.17.0.0/16"          # --service-cidr
    dns_service_ip      = "172.17.0.10"            # --dns-service-ip
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }

  # The NAT gateway must be associated with the AKS subnet before the cluster
  # is created when using outbound_type = "userAssignedNATGateway".
  depends_on = [
    azurerm_subnet_nat_gateway_association.subnet_nat_gateway_association,
    azurerm_nat_gateway_public_ip_association.nat_gateway_public_ip_association
  ]
}