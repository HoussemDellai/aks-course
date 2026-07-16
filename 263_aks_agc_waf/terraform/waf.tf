resource "azapi_resource" "waf_policy" {
  type = "Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-07-01"
  name = "waf-agc"
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  body = {
    properties = {
      customRules = [{
        name = "allowlist"
        priority = 100
        ruleType = "MatchRule"
        action = "Block"
        matchConditions = [{
          matchVariables = [{ variableName = "RemoteAddr" }]
          operator = "IPMatch"
          negationCondition = true
          matchValues = var.allowed_ip_cidrs
        }]
      }]
    }
  }
}
