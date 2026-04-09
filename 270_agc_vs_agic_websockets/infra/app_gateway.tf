# Locals block for hardcoded names
locals {
  backend_address_pool_name      = "appgw-beap"
  frontend_port_name             = "appgw-feport"
  frontend_ip_configuration_name = "appgw-feip"
  http_setting_name              = "appgw-be-htst"
  listener_name                  = "appgw-httplstn"
  request_routing_rule_name      = "appgw-rqrt"
}

# Public Ip 
resource "azurerm_public_ip" "appgw_pip" {
  name                = "public-ip-appgw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1 # 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.snet_appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }
  
  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 10000 # value from 1 to 20000
  }

  lifecycle {
    # prevent_destroy       = true
    create_before_destroy = true

    ignore_changes = [
      # all, # ignore all attributes
      tags,
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      frontend_port,
      request_routing_rule,
      url_path_map
    ]
  }
}

output "app_gateway_pip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}