output "vm_hub_public_ip" {
  value = azurerm_public_ip.pip-vm-hub.ip_address
}

output "aks_private_fqdn_001" {
  value = module.spoke-aks-001.aks_private_fqdn
}

output "aks_public_fqdn_001" {
  value = module.spoke-aks-001.aks_public_fqdn
}

output "aks_private_fqdn_002" {
  value = module.spoke-aks-002.aks_private_fqdn
}

output "aks_public_fqdn_002" {
  value = module.spoke-aks-002.aks_public_fqdn
}