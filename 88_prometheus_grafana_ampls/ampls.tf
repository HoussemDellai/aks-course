resource "azurerm_monitor_private_link_scope" "ampls" {
  name                  = "ampls-monitoring"
  resource_group_name   = azurerm_resource_group.rg.name
  ingestion_access_mode = "PrivateOnly" # Open
  query_access_mode     = "PrivateOnly" # Open
}

# resource "azapi_update_resource" "ampls-access-mode" {
#   type        = "Microsoft.Insights/privateLinkScopes@2021-07-01-preview"
#   resource_id = azurerm_monitor_private_link_scope.ampls.id

#   body = jsonencode({
#     properties = {
#       accessModeSettings = {
#         queryAccessMode     = "PrivateOnly" # "Open"
#         ingestionAccessMode = "PrivateOnly"  # "Open"
#         exclusions          = []
#       }
#     }
#   })
# }

resource "azurerm_monitor_private_link_scoped_service" "ampls-log-analytics" {
  name                = "ampls-log-analytics"
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  resource_group_name = azurerm_monitor_private_link_scope.ampls.resource_group_name
  linked_resource_id  = azurerm_log_analytics_workspace.workspace.id
}

resource "azurerm_monitor_private_link_scoped_service" "ampls-dce-log-analytics" {
  name                = "ampls-dce-log-analytics"
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  resource_group_name = azurerm_monitor_private_link_scope.ampls.resource_group_name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce-log-analytics.id
}

# # # not required, and doesn't work
# resource "azurerm_monitor_private_link_scoped_service" "prometheus" {
#   name                = "ampls-prometheus"
#   resource_group_name = azurerm_resource_group.rg.name
#   scope_name          = azurerm_monitor_private_link_scope.ampls.name
#   linked_resource_id  = azurerm_monitor_workspace.prometheus.id
# }

resource "azurerm_monitor_private_link_scoped_service" "ampls-dce-prometheus" {
  name                = "ampls-dce-prometheus"
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  resource_group_name = azurerm_monitor_private_link_scope.ampls.resource_group_name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce-prometheus.id
}
