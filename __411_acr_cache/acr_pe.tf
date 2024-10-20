# resource "azurerm_private_endpoint" "pe-acr" {
#   name                = "pe-acr"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   subnet_id           = azurerm_subnet.snet-acr.id

#   private_service_connection {
#     name                           = "connection-acr"
#     private_connection_resource_id = azurerm_container_registry.acr.id
#     is_manual_connection           = false
#     subresource_names              = ["registry"]
#   }

#   private_dns_zone_group {
#     name                 = "private-dns-zone-group-acr"
#     private_dns_zone_ids = [azurerm_private_dns_zone.private-dns-zone-acr.id]
#   }
# }

# resource "azurerm_private_dns_zone" "private-dns-zone-acr" {
#   name                = "privatelink.azurecr.io"
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "link-dns-vnet" {
#   name                  = "link-dns-vnet"
#   private_dns_zone_name = azurerm_private_dns_zone.private-dns-zone-acr.name
#   resource_group_name   = azurerm_private_dns_zone.private-dns-zone-acr.resource_group_name
#   virtual_network_id    = azurerm_virtual_network.vnet-aks.id
# }