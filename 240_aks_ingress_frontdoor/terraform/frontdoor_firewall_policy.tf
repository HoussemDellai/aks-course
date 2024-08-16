# resource "azurerm_cdn_frontdoor_firewall_policy" "waf-policy" {
#   name                = "wafpolicyapps"
#   resource_group_name = azurerm_resource_group.rg.name
#   sku_name            = "Premium_AzureFrontDoor" # Must be premium for Private Endpoint support.
#   enabled             = true
#   mode                = "Prevention"

#   managed_rule {
#     type    = "Microsoft_DefaultRuleSet"
#     version = "2.1"
#     action  = "Block"
#   }

#   managed_rule {
#     type    = "Microsoft_BotManagerRuleSet"
#     version = "1.0"
#     action  = "Block"
#   }
# }

# resource "azurerm_cdn_frontdoor_security_policy" "security-policy" {
#   name                     = "security-policy"
#   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id

#   security_policies {
#     firewall {
#       cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf-policy.id

#       association {
#         patterns_to_match = ["/*"]

#         domain {
#           cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint-aks-service.id
#         }
#       }
#     }
#   }
# }
