resource "azurerm_monitor_data_collection_rule" "dcr-log-analytics" {
  name                        = "dcr-log-analytics"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-log-analytics.id
  kind                        = "Linux"

  destinations {
    log_analytics {
      name                  = "log-analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default", "Microsoft-Syslog"]
    destinations = ["log-analytics"]
  }

  data_sources {
    syslog {
      name           = "demo-syslog"
      facility_names = ["*"]
      log_levels     = ["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency", ]
      streams        = ["Microsoft-Syslog"]
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
            namespaceFilteringMode = "Include" # "Exclude" "Off"
            namespaces             = ["kube-system", "default"]
            enableContainerLogV2   = true
          }
        }
      )
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dcra-dcr-log-analytics-aks" {
  name                    = "dcra-dcr-log-analytics-aks"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr-log-analytics.id
}
