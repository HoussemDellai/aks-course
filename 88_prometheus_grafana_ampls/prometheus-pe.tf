resource "azurerm_private_endpoint" "pe-prometheus" {
  name                = "pe-prometheus"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.snet-pe.id

  private_service_connection {
    name                           = "connection"
    is_manual_connection           = false
    subresource_names              = ["prometheusMetrics"]
    private_connection_resource_id = azurerm_monitor_workspace.prometheus.id
  }

  private_dns_zone_group {
    name                 = "private-dns-zone"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone-prometheus.id]
  }
}

resource "azurerm_private_dns_zone" "zone-prometheus" {
  name                = "privatelink.${var.location}.prometheus.monitor.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link-prometheus" {
  name                  = "vnet-link-prometheus"
  private_dns_zone_name = azurerm_private_dns_zone.zone-prometheus.name
  resource_group_name   = azurerm_private_dns_zone.zone-prometheus.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
