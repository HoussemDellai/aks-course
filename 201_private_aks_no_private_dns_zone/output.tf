output "aks_public_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_private_fqdn" {
  value = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "vm_hub_public_ip" {
  value = azurerm_public_ip.pip-vm-hub.ip_address
}