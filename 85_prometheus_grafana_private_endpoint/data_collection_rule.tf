resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = "dcr-prometheus"
  resource_group_name         = azurerm_resource_group.rg_monitoring.name
  location                    = azurerm_resource_group.rg_monitoring.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
  kind                        = "Linux"

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
      name               = azurerm_monitor_workspace.prometheus.name
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = [azurerm_monitor_workspace.prometheus.name]
  }
}

# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "dcr-aks" {
  name                    = "dcr-aks"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
}