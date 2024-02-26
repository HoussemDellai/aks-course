output "query_endpoint" {
  value = azurerm_monitor_workspace.prometheus.query_endpoint
}

output "garafana_endpoint" {
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