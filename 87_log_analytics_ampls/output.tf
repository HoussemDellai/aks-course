output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_rg_name" {
  value = azurerm_kubernetes_cluster.aks.resource_group_name
}