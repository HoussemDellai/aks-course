
data "azurerm_monitor_diagnostic_categories" "categories" {
  resource_id = azurerm_firewall.firewall.id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic-setting" {
  name                           = "diagnostic-setting"
  target_resource_id             = azurerm_firewall.firewall.id
  log_analytics_destination_type = "Dedicated" # "AzureDiagnostics"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.workspace.id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.categories.log_category_types

    content {
      category = enabled_log.key
    }
  }

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.categories.metrics

    content {
      category = enabled_metric.key
    }
  }
}



