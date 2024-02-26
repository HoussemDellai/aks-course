resource "azurerm_monitor_data_collection_endpoint" "dce-log-analytics" {
  name                          = "dce-log-analytics1"
  resource_group_name           = azurerm_resource_group.rg_monitoring.name
  location                      = azurerm_resource_group.rg_monitoring.location
  public_network_access_enabled = false
}

# associate to a Data Collection Endpoint
resource "azurerm_monitor_data_collection_rule_association" "dce-aks" {
  target_resource_id          = azurerm_kubernetes_cluster.aks.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-log-analytics.id
}

# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "dcr-aks1" {
  name                    = "dcr-aks1"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr-log-analytics.id
}

resource "azurerm_monitor_data_collection_rule" "dcr-log-analytics" {
  name                        = "dcr-log-analytics1"
  resource_group_name         = azurerm_resource_group.rg_monitoring.name
  location                    = azurerm_resource_group.rg_monitoring.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-log-analytics.id

  destinations {
    log_analytics {
      name                  = "log_analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["log_analytics"]
  }

  data_sources {
    syslog {
      name = "example-syslog"
      #   streams = ["Microsoft-Syslog"]
      facility_names = [
        "*"
      ]
      log_levels = [
        "Debug",
        "Info",
        "Notice",
        "Warning",
        "Error",
        "Critical",
        "Alert",
        "Emergency",
      ]
    }
    extension {
      extension_name = "ContainerInsights"
      name           = "ContainerInsightsExtension"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_json = jsonencode(
        {
          dataCollectionSettings = {
            enableContainerLogV2   = true
            interval               = "1m"
            namespaceFilteringMode = "Off"
          }
        }
      )
      #   extension_json = jsonencode("\"dataCollectionSettings\": { \"interval\": \"1m\", \"namespaceFilteringMode\": \"Off\", \"enableContainerLogV2\": true }\"")
    }
  }
}
