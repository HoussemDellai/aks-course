resource "azurerm_cdn_frontdoor_endpoint" "endpoint-aks-service" {
  name                     = "endpoint-aks-service"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin-group-aks-service" {
  name                     = "origin-group-aks-service"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin-aks-service" {
  name                          = "origin-aks-service"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group-aks-service.id

  enabled                        = true
  host_name                      = "10.10.0.25"
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = "10.10.0.25"
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    private_link_target_id = "/subscriptions/38977b70-47bf-4da5-a492-88712fce8725/resourceGroups/mc_rg-aks-frontdoor-240-swc_aks-cluster_swedencentral/providers/Microsoft.Network/privateLinkServices/pls-aks-service"
    # target_type            = "privateLinkServices" # cannot be specified when using a Load Balancer as an Origin.
    request_message = "Request access for Azure Front Door Private Link origin"
    location        = var.location
  }
}

resource "azurerm_cdn_frontdoor_route" "route-aks-service" {
  name                          = "route-aks-service"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint-aks-service.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group-aks-service.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin-aks-service.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpOnly" # "HttpsOnly"
  link_to_default_domain        = true
  https_redirect_enabled        = false
  cdn_frontdoor_origin_path     = "/"
}
