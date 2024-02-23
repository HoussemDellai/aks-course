output "query_endpoint" {
  value = azurerm_monitor_workspace.prometheus.query_endpoint
}

output "garafana_endpoint" {
  value = azurerm_dashboard_grafana.grafana.endpoint
}