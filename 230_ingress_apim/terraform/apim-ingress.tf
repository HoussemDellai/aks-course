resource "azurerm_api_management_api" "api-albums" {
  name                  = "api-albums"
  resource_group_name   = azurerm_api_management.apim.resource_group_name
  api_management_name   = azurerm_api_management.apim.name
  revision              = "1"
  display_name          = "api-albums"
  path                  = "albums"
  api_type              = "http" # graphql, http, soap, and websocket
  protocols             = ["http", "https"]
  service_url           = "http://10.10.0.7/albums" # Private IP of the Ingress Controller
  subscription_required = false
}

resource "azurerm_api_management_api_operation" "operation-get-albums" {
  operation_id        = "api-albums-get"
  api_name            = azurerm_api_management_api.api-albums.name
  api_management_name = azurerm_api_management_api.api-albums.api_management_name
  resource_group_name = azurerm_api_management_api.api-albums.resource_group_name
  display_name        = "GET"
  method              = "GET"
  url_template        = "/"
  description         = "GET returns sample JSON file."
}
