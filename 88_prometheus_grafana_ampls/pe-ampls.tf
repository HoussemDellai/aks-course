locals {
  dns_zones_ampls = toset([
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.blob.core.windows.net",
  ])
}

resource "azurerm_private_endpoint" "pe-ampls" {
  name                = "pe-ampls"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.snet-pe.id

  private_service_connection {
    name                           = "connection"
    is_manual_connection           = false
    subresource_names              = ["azuremonitor"]
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
  }

  private_dns_zone_group {
    name                 = "private-dns-zone"
    private_dns_zone_ids = [for zone in azurerm_private_dns_zone.zones : zone.id]
  }
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = local.dns_zones_ampls
  name                = each.value
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  for_each              = azurerm_private_dns_zone.zones
  name                  = "vnet-link-${each.key}"
  private_dns_zone_name = each.value.name
  resource_group_name   = each.value.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
