output "custom_domain_name" {
  value = azurerm_dns_cname_record.dns_cname_record.fqdn
}

output "agc_frontend_fqdn" {
  value = azurerm_application_load_balancer_frontend.agc_frontend.fully_qualified_domain_name
}
