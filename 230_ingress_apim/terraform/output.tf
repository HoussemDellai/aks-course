output "api_url" {
    value = "${azurerm_api_management.apim.gateway_url}/${azurerm_api_management_api.api-albums.path}"
}