resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster-swc"
  location            = azurerm_resource_group.rg-spoke.location
  resource_group_name = azurerm_resource_group.rg-spoke.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.30.5"

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "userDefinedRouting"
  }

  default_node_pool {
    name                        = "systempool"
    temporary_name_for_rotation = "syspool"
    node_count                  = 3
    vm_size                     = "standard_b2als_v2"
    zones                       = [1, 2, 3]
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

  depends_on = [
    azurerm_subnet_route_table_association.association_route_table_subnet_spoke,
    azurerm_route.route-to-nva-spoke,
    azurerm_route.route-firewall-ip
  ]
}

resource "azapi_resource" "nodepool-egress" {
  type                      = "Microsoft.ContainerService/managedClusters/agentPools@2024-09-02-preview"
  parent_id                 = azurerm_kubernetes_cluster.aks.id
  name                      = "npegresspr"
  schema_validation_enabled = false

  body = {
    properties = {
      count  = 2
      mode   = "Gateway"
      vmSize = "standard_d2pds_v6"
      nodeTaints = [
        "kubernetes.azure.com/mode=gateway:NoSchedule"
      ]
    }
  }

  depends_on = [azapi_update_resource.enable-aks-static-egress-gateway]
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [azurerm_kubernetes_cluster.aks.id]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}

resource "azurerm_role_assignment" "network-contributor" {
  scope                = azurerm_resource_group.rg-spoke.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}

resource "azurerm_role_assignment" "network-contributor-aks" {
  scope                = azurerm_kubernetes_cluster.aks.node_resource_group_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}

resource "azurerm_role_assignment" "virtual-machine-contributor" {
  scope                = azurerm_kubernetes_cluster.aks.node_resource_group_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}
