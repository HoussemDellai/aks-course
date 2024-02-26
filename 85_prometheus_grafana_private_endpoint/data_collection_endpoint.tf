resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                          = "dce-prometheus"
  resource_group_name           = azurerm_resource_group.rg_monitoring.name
  location                      = azurerm_resource_group.rg_monitoring.location
  kind                          = "Linux"
  public_network_access_enabled = true # false
}

# # # associate to a Data Collection Endpoint
# # resource "azurerm_monitor_data_collection_rule_association" "dce-aks" {
# #   target_resource_id          = azurerm_kubernetes_cluster.aks.id
# #   data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
# # }