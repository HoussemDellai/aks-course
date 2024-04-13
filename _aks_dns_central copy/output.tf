output "aks_public_fqdn" {
  value = {
    for k, v in azurerm_kubernetes_cluster.aks : k => v.fqdn
  }
}

output "aks_private_fqdn" {
    value = {
    for k, v in azurerm_kubernetes_cluster.aks : k => v.private_fqdn
  }
}

output "vm_hub_public_ip" {
  value = azurerm_public_ip.pip-vm-hub.ip_address
}
