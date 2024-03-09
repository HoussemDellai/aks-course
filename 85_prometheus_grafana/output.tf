output "prometheus_query_endpoint" {
  value = azurerm_monitor_workspace.prometheus.query_endpoint
}

output "garafana" {
  value = azurerm_dashboard_grafana.grafana.endpoint
}

output "grafana_name" {
  value = azurerm_dashboard_grafana.grafana.name
}

output "grafana_rg_name" {
  value = azurerm_dashboard_grafana.grafana.resource_group_name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_rg_name" {
  value = azurerm_kubernetes_cluster.aks.resource_group_name
}

output "dce-prometheus" {
  value = {
    logs_ingestion_endpoint       = azurerm_monitor_data_collection_endpoint.dce-prometheus.logs_ingestion_endpoint
    configuration_access_endpoint = azurerm_monitor_data_collection_endpoint.dce-prometheus.configuration_access_endpoint
    # metrics_ingestion_endpoint       = azurerm_monitor_data_collection_endpoint.dce-prometheus.metrics_ingestion_endpoint # not yet in Terraform
  }
}

output "loganalytics" {
  value = azurerm_log_analytics_workspace.workspace.workspace_id
}