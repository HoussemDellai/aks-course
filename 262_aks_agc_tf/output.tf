output "custom_domain_name" {
  value = azurerm_dns_cname_record.dns_cname_record.fqdn
}

output "agc-frontend-fqdn" {
  value = azurerm_application_load_balancer_frontend.agc.fully_qualified_domain_name
}
