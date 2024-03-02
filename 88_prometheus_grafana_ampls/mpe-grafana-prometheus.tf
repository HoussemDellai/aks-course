# use AzAPI to create Grafana Managed Private Endpoint

resource "azapi_resource" "mpe-grafana" {
  type      = "microsoft.dashboard/grafana/managedprivateendpoints@2023-09-01"
  name      = "mpe-grafana"
  parent_id = azurerm_dashboard_grafana.grafana.id
  location  = azurerm_dashboard_grafana.grafana.location

  body = jsonencode({
    properties = {
      privateLinkResourceId : azurerm_monitor_workspace.prometheus.id,
      privateLinkResourceRegion : azurerm_dashboard_grafana.grafana.location,
      groupIds : [ "prometheusMetrics" ],
      requestMessage : ""
    }
  })
}
