resource "azurerm_private_endpoint" "pe-grafana" {
  name                = "pe-grafana"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.snet-pe.id

  private_service_connection {
    name                           = "connection"
    is_manual_connection           = false
    subresource_names              = ["grafana"]
    private_connection_resource_id = azurerm_dashboard_grafana.grafana.id
  }

  private_dns_zone_group {
    name                 = "private-dns-zone"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone-grafana.id]
  }
}

resource "azurerm_private_dns_zone" "zone-grafana" {
  name                = "privatelink.grafana.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link-grafana" {
  name                  = "vnet-link-grafana"
  private_dns_zone_name = azurerm_private_dns_zone.zone-grafana.name
  resource_group_name   = azurerm_private_dns_zone.zone-grafana.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
