# resource "azurerm_private_endpoint" "example" {
#   name                = "example-endpoint"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   subnet_id           = azurerm_subnet.example.id

#   private_service_connection {
#     name                           = "example-privateserviceconnection"
#     private_connection_resource_id = azurerm_storage_account.example.id
#     subresource_names              = ["blob"]
#     is_manual_connection           = false
#   }

#   private_dns_zone_group {
#     name                 = "example-dns-zone-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.example.id]
#   }
# }