output "aks_webapp_routing" {
  value = azurerm_kubernetes_cluster.aks.web_app_routing
}

output "custom_domain_name" {
  value = azurerm_dns_zone.dns_zone.name
}

output "private_domain_name" {
  value = azurerm_private_dns_zone.private_dns_zone.name
}

output "keyvault_tls_cert_url" {
  value = azurerm_key_vault_certificate.aks-ingress-tls-01.versionless_id
}