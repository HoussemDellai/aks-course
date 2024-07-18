locals {
  front_door_profile_name         = "frontdoor-aks-apps"
  front_door_sku_name             = "Premium_AzureFrontDoor" // Must be premium for Private Link support.
  front_door_endpoint_name        = "frontdoor-240"
  front_door_origin_group_name    = "origin-group-01"
  front_door_origin_name          = "origin-aks-ingress"
  front_door_route_name           = "route-aks-ingress"
  front_door_origin_path          = "/albums" // The path to the blob container.
  front_door_custom_domain_name   = "frontdoor-houssemdellai01-com"
  front_door_firewall_policy_name = "wafpolicy"
  front_door_security_policy_name = "security-policy"
}

resource "azurerm_cdn_frontdoor_profile" "frontdoor" {
  name                = local.front_door_profile_name
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = local.front_door_sku_name
}

resource "azurerm_cdn_frontdoor_endpoint" "frontdoor-endpoint" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
}

resource "azurerm_cdn_frontdoor_origin_group" "frontdoor-origin-group" {
  name                     = local.front_door_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "frontdoor-origin" {
  name                          = local.front_door_origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor-origin-group.id

  enabled                        = true
  host_name                      = "10.10.0.25"
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = "10.10.0.25"
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    private_link_target_id = "/subscriptions/38977b70-47bf-4da5-a492-88712fce8725/resourceGroups/mc_rg-aks-frontdoor-240_aks-cluster_swedencentral/providers/Microsoft.Network/privateLinkServices/pls-aks-service"
    # target_type            = "privateLinkServices" # cannot be specified when using a Load Balancer as an Origin.
    request_message        = "Request access for Azure Front Door Private Link origin"
    location               = var.front_door_private_link_location
  }
}

resource "azurerm_cdn_frontdoor_route" "frontdoor-route" {
  name                          = local.front_door_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontdoor-endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor-origin-group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontdoor-origin.id]

  supported_protocols       = ["Http", "Https"]
  patterns_to_match         = ["/*"]
  forwarding_protocol       = "HttpOnly" # "HttpsOnly"
  link_to_default_domain    = true
  https_redirect_enabled    = false
  cdn_frontdoor_origin_path = local.front_door_origin_path

  cdn_frontdoor_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.frontdoor-custom-domain.id
  ]
}

resource "azurerm_cdn_frontdoor_custom_domain" "frontdoor-custom-domain" {
  name                     = local.front_door_custom_domain_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
  host_name                = var.custom_domain_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "frontdoor-waf-policy" {
  name                = local.front_door_firewall_policy_name
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = local.front_door_sku_name
  enabled             = true
  mode                = var.waf_mode

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "frontdoor-security-policy" {
  name                     = local.front_door_security_policy_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.frontdoor-waf-policy.id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.frontdoor-custom-domain.id
        }
      }
    }
  }
}
