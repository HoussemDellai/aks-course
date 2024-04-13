# Deploy DNS Private Zone for AKS
resource "azurerm_private_dns_zone" "private_dns_zone" {
  for_each = tomap(var.spokes)

  name                = "${each.key}.privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.rg-hub.name
}

resource "azurerm_role_assignment" "private-dns-zone-contributor" {
  for_each = tomap(var.spokes)

  scope                = azurerm_private_dns_zone.private_dns_zone[each.key].id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.identity-aks[each.key].principal_id
}

# Network Contributor Role Assignment
resource "azurerm_role_assignment" "network-contributor" {
  for_each = tomap(var.spokes)

  scope                = azurerm_virtual_network.vnet-spoke[each.key].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.identity-aks[each.key].principal_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "link-private_dns_zone-to-vnet-hub" {
  for_each = tomap(var.spokes)

  name                  = "link-private_dns_zone-to-vnet-hub"
  resource_group_name   = azurerm_private_dns_zone.private_dns_zone[each.key].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet-hub.id
}
