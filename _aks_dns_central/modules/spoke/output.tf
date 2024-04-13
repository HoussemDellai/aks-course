output "aks_public_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_private_fqdn" {
    value = azurerm_kubernetes_cluster.aks.private_fqdn
}