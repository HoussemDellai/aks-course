locals {
  resources = [
    {
      type = "aks"
      id   = azurerm_kubernetes_cluster.aks.id
    },
    # {
    #   type = "grafana"
    #   id   = azurerm_dashboard_grafana.grafana.id
    # }
  ]
}

data "azurerm_monitor_diagnostic_categories" "resources" {
  #   for_each = [azurerm_kubernetes_cluster.aks.id]
  for_each = { for resource in local.resources : resource.type => resource }

  resource_id = each.value.id
}

resource "azurerm_monitor_diagnostic_setting" "rule" {
  for_each = { for resource in local.resources : resource.type => resource }

  name                           = "diagnostic-setting"
  target_resource_id             = each.value.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.workspace.id
  log_analytics_destination_type = "AzureDiagnostics"

  dynamic "enabled_log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.resources[each.key].log_category_types

    content {
      category = entry.value
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.resources[each.key].metrics

    content {
      category = entry.value
      enabled  = true
    }
  }
}
