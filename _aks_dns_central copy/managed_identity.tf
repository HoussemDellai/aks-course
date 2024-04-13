resource "azurerm_user_assigned_identity" "identity-aks" {
  for_each = tomap(var.spokes)

  name                = "identity-aks"
  resource_group_name = azurerm_resource_group.rg-spoke[each.key].name
  location            = azurerm_resource_group.rg-spoke[each.key].location
}

resource "azurerm_role_assignment" "contributor" {
  for_each = tomap(var.spokes)

  scope                = azurerm_private_dns_zone.private_dns_zone[each.key].id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.identity-aks[each.key].principal_id
}
