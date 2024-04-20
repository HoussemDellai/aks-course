resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "internal.${var.custom_domain_name}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "test" {
  name                = "test"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = azurerm_private_dns_zone.private_dns_zone.resource_group_name
  ttl                 = 300
  records             = ["10.11.12.13"]
}

resource "azurerm_private_dns_zone_virtual_network_link" "link-vnet" {
  name                  = "link-vnet"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet-aks.id
}