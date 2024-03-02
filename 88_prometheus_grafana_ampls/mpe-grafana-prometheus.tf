# use AzAPI to create Grafana Managed Private Endpoint

# PUT https://management.azure.com/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Dashboard/grafana/myWorkspace/managedPrivateEndpoints/myMPEName?api-version=2023-09-01
# {
#   "properties": {
#     "privateLinkResourceId": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-000000000000/resourceGroups/xx-rg/providers/Microsoft.Kusto/Clusters/sampleKustoResource",
#     "privateLinkResourceRegion": "West US",
#     "groupIds": [
#       "grafana"
#     ],
#     "requestMessage": "Example Request Message",
#     "privateLinkServiceUrl": "my-self-hosted-influxdb.westus.mydomain.com"
#   },
#   "location": "West US"
# }

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
