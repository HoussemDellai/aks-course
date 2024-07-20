resource "azurerm_cdn_frontdoor_endpoint" "endpoint-aks-ingress" {
  name                     = "endpoint-aks-ingress"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin-group-aks-ingress" {
  name                     = "origin-group-aks-ingress"
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

resource "azurerm_cdn_frontdoor_origin" "origin-aks-ingress" {
  name                          = "origin-aks-ingress"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group-aks-ingress.id

  enabled                        = true
  host_name                      = "10.10.0.30"
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = "10.10.0.30"
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    private_link_target_id = data.azurerm_private_link_service.pls-ingress.id
    # private_link_target_id = "${azurerm_kubernetes_cluster.aks.node_resource_group_id}/providers/Microsoft.Network/privateLinkServices/${var.pls_ingress_name}"
    # target_type            = "privateLinkServices" # cannot be specified when using a Load Balancer as an Origin.
    request_message = "Request access for Azure Front Door Private Link origin"
    location        = var.location
  }
}

resource "azurerm_cdn_frontdoor_route" "route-aks-ingress" {
  name                          = "route-aks-ingress"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint-aks-ingress.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group-aks-ingress.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin-aks-ingress.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpOnly" # "HttpsOnly"
  link_to_default_domain        = true
  https_redirect_enabled        = false
  cdn_frontdoor_origin_path     = "/"
}