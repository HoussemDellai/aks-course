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