# resource "azurerm_private_dns_zone" "example" {
#   name                = "privatelink.blob.core.windows.net"
#   resource_group_name = azurerm_resource_group.example.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "example" {
#   name                  = "example-link"
#   resource_group_name   = azurerm_resource_group.example.name
#   private_dns_zone_name = azurerm_private_dns_zone.example.name
#   virtual_network_id    = azurerm_virtual_network.example.id
# }