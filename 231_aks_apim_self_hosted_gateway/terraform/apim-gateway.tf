resource "azurerm_api_management_gateway" "gateway" {
  name              = "gateway-aks"
  api_management_id = azurerm_api_management.apim.id
  description       = "API Management self-hosted gateway in an AKS cluster"

  location_data {
    name     = "AKS on Azure"
    city     = "example city"
    district = "example district"
    region   = var.location
  }
}

resource "azurerm_api_management_gateway_api" "gateway-api" {
  gateway_id = azurerm_api_management_gateway.gateway.id
  api_id     = azurerm_api_management_api.api-albums.id
}