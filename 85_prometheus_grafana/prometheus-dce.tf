resource "azurerm_monitor_data_collection_endpoint" "dce-prometheus" {
  name                          = "dce-prometheus"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  kind                          = "Linux"
  public_network_access_enabled = true
}