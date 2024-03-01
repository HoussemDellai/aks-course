resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = "ampls-monitoring"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_monitor_private_link_scoped_service" "ampls-log-analytics" {
  name                = "ampls-log-analytics"
  resource_group_name = azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.workspace.id
}

resource "azurerm_monitor_private_link_scoped_service" "ampls-dce-log-analytics" {
  name                = "ampls-dce-log-analytics"
  resource_group_name = azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce-log-analytics.id
}


# # not required
# # resource "azurerm_monitor_private_link_scoped_service" "prometheus" {
# #   name                = "ampls-prometheus"
# #   resource_group_name = azurerm_resource_group.rg_monitoring.name
# #   scope_name          = azurerm_monitor_private_link_scope.ampls.name
# #   linked_resource_id  = azurerm_monitor_workspace.prometheus.id
# # }

# resource "azurerm_monitor_private_link_scoped_service" "dce-prometheus" {
#   name                = "ampls-dce-prometheus"
#   resource_group_name = azurerm_resource_group.rg_monitoring.name
#   scope_name          = azurerm_monitor_private_link_scope.ampls.name
#   linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce-prometheus.id
# }