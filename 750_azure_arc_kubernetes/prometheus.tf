resource "azurerm_monitor_workspace" "prometheus" {
  name                = "monitor-workspace-prometheus-${var.prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# resource "azurerm_monitor_data_collection_endpoint" "data_collection_endpoint" {
#   name                = "prometheus-data-collection-endpoint"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   kind                = "Linux"
# }

# resource "azurerm_monitor_data_collection_rule" "data_collection_rule" {
#   name                        = "prometheus-data-collection-rule"
#   resource_group_name         = azurerm_resource_group.rg.name
#   location                    = azurerm_resource_group.rg.location
#   data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.data_collection_endpoint.0.id

#   data_sources {
#     prometheus_forwarder {
#       name    = "PrometheusDataSource"
#       streams = ["Microsoft-PrometheusMetrics"]
#     }
#   }

#   destinations {
#     monitor_account {
#       monitor_account_id = azurerm_monitor_workspace.prometheus.0.id
#       name               = azurerm_monitor_workspace.prometheus.0.name
#     }
#   }

#   data_flow {
#     streams      = ["Microsoft-PrometheusMetrics"]
#     destinations = [azurerm_monitor_workspace.prometheus.0.name]
#   }
# }

# # # associate to a Data Collection Rule
# # resource "azurerm_monitor_data_collection_rule_association" "dcr_to_aks" {
# #   name                    = "dcr-aks"
# #   target_resource_id      = azurerm_kubernetes_cluster.aks.id
# #   data_collection_rule_id = azurerm_monitor_data_collection_rule.data_collection_rule.id
# # }

# # # associate to a Data Collection Endpoint
# # resource "azurerm_monitor_data_collection_rule_association" "dce_to_aks" {
# #   target_resource_id          = azurerm_kubernetes_cluster.aks.id
# #   data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.data_collection_endpoint.id
# # }

resource "azurerm_role_assignment" "role_monitoring_data_reader_me" {
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}
