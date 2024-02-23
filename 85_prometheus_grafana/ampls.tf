resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = "ampls-monitoring"
  resource_group_name = azurerm_resource_group.rg_monitoring.name
}

resource "azurerm_monitor_private_link_scoped_service" "ampls-law" {
  name                = "law-lss-monitoring"
  resource_group_name = azurerm_resource_group.rg_monitoring.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.workspace.id
}

resource "azurerm_monitor_private_link_scoped_service" "ampls-dce" {
  name                = "ampls-dce"
  resource_group_name = azurerm_resource_group.rg_monitoring.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce.id
}