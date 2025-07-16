locals {
  backend_address_pool_name      = "backend_address_pool"
  frontend_port_name             = "frontend_port"
  frontend_ip_configuration_name = "frontend_ip_configuration"
  http_setting_name              = "http_setting"
  listener_name                  = "listener"
  request_routing_rule_name      = "request_routing_rule"
  redirect_configuration_name    = "redirect_configuration"
}

resource "azurerm_public_ip" "pip-appgateway" {
  name                = "pip-appgateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgateway" {
  name                = "appgateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2" # "WAF_v2"
    tier     = "Standard_v2" # "WAF_v2"
    capacity = 1
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip-appgateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = ["10.10.1.10"] # ["10.10.0.10"] # IP address of the exposed private ingress service
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.snet-appgateway.id
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  probe {
    name                                      = "http-health-probe"
    protocol                                  = "Http"
    pick_host_name_from_backend_http_settings = true
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    minimum_servers                           = 0
  }
}

output "pip_app_gateway" {
  value = azurerm_public_ip.pip-appgateway.ip_address
}