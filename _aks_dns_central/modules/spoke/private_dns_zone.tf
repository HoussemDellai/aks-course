resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "${var.prefix}.privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.rg-spoke.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link-private_dns_zone-to-vnet-hub" {
  name                  = "link-private_dns_zone-to-vnet-hub"
  resource_group_name   = azurerm_private_dns_zone.private_dns_zone.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.vnet_hub_id
}
