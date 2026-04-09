resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                       = "log-analytics"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  sku                        = "PerGB2018"
  retention_in_days          = 30
  daily_quota_gb             = -1
}

data "azurerm_monitor_diagnostic_categories" "categories_agc" {
  resource_id = azurerm_application_load_balancer.agc.id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostics_agc" {
  name                           = "diagnostics-agc"
  target_resource_id             = azurerm_application_load_balancer.agc.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log_analytics.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.categories_agc.log_category_types

    content {
      category = enabled_log.key
    }
  }

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.categories_agc.metrics

    content {
      category = enabled_metric.key
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "categories_appgateway" {
  resource_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway.0.effective_gateway_id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostics_appgateway" {
  name                           = "diagnostics-appgateway"
  target_resource_id             = azurerm_kubernetes_cluster.aks.ingress_application_gateway.0.effective_gateway_id 
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log_analytics.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.categories_appgateway.log_category_types

    content {
      category = enabled_log.key
    }
  }

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.categories_appgateway.metrics

    content {
      category = enabled_metric.key
    }
  }
}