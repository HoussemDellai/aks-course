output "endpoint-aks-ingress" {
  value = azurerm_cdn_frontdoor_endpoint.endpoint-aks-ingress.host_name
}

output "endpoint-aks-service" {
  value = azurerm_cdn_frontdoor_endpoint.endpoint-aks-service.host_name
}