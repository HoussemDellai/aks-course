output "frontdoor_endpoint" {
  value = azurerm_cdn_frontdoor_endpoint.frontdoor-endpoint.host_name
}