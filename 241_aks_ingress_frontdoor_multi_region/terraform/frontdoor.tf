resource "azurerm_cdn_frontdoor_profile" "frontdoor" {
  name                = "frontdoor-aks-apps"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Premium_AzureFrontDoor" # Must be premium for Private Link support.
}